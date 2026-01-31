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
    --without-gettext

# Build only smbcacls
RUN make -j$(nproc) bin/smbcacls

# Final image with runtime dependencies
FROM alpine:3.19

# Install runtime dependencies
RUN apk add --no-cache \
    gnutls talloc tdb tevent popt iniparser \
    libarchive

# Copy the compiled smbcacls binary
COPY --from=builder /build/samba/bin/default/source3/utils/smbcacls /usr/local/bin/smbcacls

# Make it executable
RUN chmod +x /usr/local/bin/smbcacls

# Test the binary
RUN /usr/local/bin/smbcacls --help | grep -q max-depth && echo "Custom smbcacls with --max-depth support"

ENTRYPOINT ["/usr/local/bin/smbcacls"]
CMD ["--help"]
