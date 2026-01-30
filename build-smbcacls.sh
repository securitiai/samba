#!/bin/sh
set -e

echo "Installing dependencies..."
if [ "$(uname)" = "Darwin" ]; then
  # macOS with Homebrew
  brew install gnutls talloc tdb tevent popt iniparser libarchive bison flex m4

  # Use Homebrew bison and m4 instead of system versions (which are too old)
  export PATH="/usr/local/opt/bison/bin:/usr/local/opt/m4/bin:$PATH"
else
  # Alpine Linux
  apk add --no-cache gcc g++ make python3 perl flex bison \
    gnutls-dev talloc-dev tdb-dev tevent-dev ldb-dev popt-dev \
    linux-headers musl-dev iniparser-dev
fi

echo "Configuring Samba..."
./configure \
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

echo "Building smbcacls..."
make -j4 bin/smbcacls

echo "Build complete!"
ls -lh bin/default/source3/utils/smbcacls
