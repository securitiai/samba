# Dockerfile to build custom smbcacls with --max-depth support
FROM alpine:3.19 AS builder

# Install build dependencies including git
RUN apk add --no-cache \
    gcc g++ make python3 perl perl-parse-yapp flex bison m4 \
    gnutls-dev talloc-dev tdb-dev tevent-dev popt-dev iniparser-dev \
    libarchive-dev git

# Clone forked Samba repo with custom changes (--max-depth support)
ARG SAMBA_REPO=https://github.com/securitiai/samba.git
ARG SAMBA_BRANCH=custom-max-depth

WORKDIR /build
RUN git clone --depth 1 --branch ${SAMBA_BRANCH} ${SAMBA_REPO} samba

WORKDIR /build/samba

# Configure Samba (minimal build for smbcacls only)
RUN ./configure \
    --disable-python \
    --without-ad-dc \
    --without-ads \
    --without-acl-support \
    --without-json \
    --without-ldap \
    --disable-cups \
    --without-ldb-lmdb \
    --without-libunwind \
    --without-libarchive \
    --disable-fault-handling \
    --without-pam \
    --without-gettext \
    --with-shared-modules='!vfs_snapper'

# Build only smbcacls
RUN make -j$(nproc) bin/smbcacls

# Final image with runtime dependencies
FROM alpine:3.19

# Install runtime dependencies
RUN apk add --no-cache \
    gnutls talloc tdb tevent popt iniparser \
    libarchive

# Copy the entire bin directory to preserve library structure
COPY --from=builder /build/samba/bin/ /usr/local/samba/bin/

# Create entrypoint script that sets up library paths dynamically
RUN cat > /entrypoint.sh <<'EOF'
#!/bin/sh
# Build LD_LIBRARY_PATH from all directories containing .so files
export LD_LIBRARY_PATH=$(find /usr/local/samba/bin -name "*.so*" -exec dirname {} \; | sort -u | tr "\n" ":")
exec /usr/local/samba/bin/default/source3/utils/smbcacls "$@"
EOF

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["--help"]
