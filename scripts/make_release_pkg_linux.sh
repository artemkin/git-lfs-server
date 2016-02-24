#!/bin/sh

set -e
set -o pipefail

# check pam-devel is installed
# echo "#include <security/pam_appl.h>" | gcc -E - &> /dev/null; echo $?
./scripts/check_pam.sh

ocamlbuild -clean
./scripts/build.sh src/lfs_config.native
./scripts/build.sh src/lfs_server.native

rm -rf lfs_server
mkdir lfs_server
mkdir lfs_server/bin
mkdir lfs_server/lib
cp scripts/lfs_server.sh lfs_server/
cp lfs_server.native lfs_server/bin/lfs_server
strip lfs_server/bin/lfs_server
cp `ldd lfs_server/bin/lfs_server | grep libssl | cut -d ' ' -f3` lfs_server/lib/
cp `ldd lfs_server/bin/lfs_server | grep libcrypto | cut -d ' ' -f3` lfs_server/lib/

VERSION=`./lfs_config.native version`
tar cvf - lfs_server | gzip -9 - > lfs_server-${VERSION}-linux.x64.tar.gz

