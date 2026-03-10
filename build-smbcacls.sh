#!/bin/sh
set -e

echo "Installing dependencies..."
if [ "$(uname)" = "Darwin" ]; then
  # macOS with Homebrew
  brew install gnutls talloc tdb tevent popt iniparser libarchive bison flex m4

  # Use Homebrew bison and m4 instead of system versions (which are too old)
  export PATH="/usr/local/opt/bison/bin:/usr/local/opt/m4/bin:$PATH"

  # Install Parse::Yapp via CPAN if not already installed
  if ! perl -MParse::Yapp -e '' 2>/dev/null; then
    echo "Installing Parse::Yapp via CPAN..."
    sudo cpan -i Parse::Yapp
  else
    echo "Parse::Yapp is already installed"
  fi
elif [ -f /etc/debian_version ]; then
  # Debian/Ubuntu
  echo "Detected Debian/Ubuntu..."
  sudo apt-get update
  sudo apt-get install -y gcc g++ make python3 perl libyapp-perl flex bison \
    libgnutls28-dev libtalloc-dev libtdb-dev libtevent-dev libpopt-dev \
    libiniparser-dev libarchive-dev pkg-config
elif [ -f /etc/redhat-release ]; then
  # RHEL/CentOS/Fedora
  echo "Detected RHEL/CentOS/Fedora..."
  sudo yum install -y gcc gcc-c++ make python3 perl perl-Parse-Yapp flex bison \
    gnutls-devel libtalloc-devel libtdb-devel libtevent-devel popt-devel \
    iniparser-devel libarchive-devel pkgconfig
elif command -v apk >/dev/null 2>&1; then
  # Alpine Linux
  echo "Detected Alpine Linux..."
  apk add --no-cache gcc g++ make python3 perl perl-parse-yapp flex bison \
    gnutls-dev talloc-dev tdb-dev tevent-dev ldb-dev popt-dev \
    linux-headers musl-dev iniparser-dev libarchive-dev
else
  echo "Unsupported OS. Please install dependencies manually."
  echo "Required: gcc, g++, make, python3, perl, Parse::Yapp, flex, bison"
  echo "          gnutls, talloc, tdb, tevent, popt, iniparser, libarchive"
  exit 1
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
  --without-gettext \
  --with-shared-modules='!vfs_snapper'

echo "Building smbcacls..."
make -j4 bin/smbcacls

echo "Build complete!"
echo ""
echo "Binary location: bin/default/source3/utils/smbcacls"
ls -lh bin/default/source3/utils/smbcacls
