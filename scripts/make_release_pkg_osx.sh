#!/bin/sh

ocamlbuild -clean
./scripts/build.sh lfs_config.native
./scripts/build.sh lfs_server.native

mkdir lfs_server
mkdir lfs_server/bin
mkdir lfs_server/lib
cp scripts/lfs_server-osx.sh lfs_server/lfs_server.sh
cp _build/lfs_server.native lfs_server/bin/lfs_server
strip lfs_server/bin/lfs_server
cp `otool -L lfs_server/bin/lfs_server | grep libssl | cut -d ' ' -f1` lfs_server/lib/
cp `otool -L lfs_server/bin/lfs_server | grep libcrypto | cut -d ' ' -f1` lfs_server/lib/

VERSION=`./lfs_config.native version`
tar cvf - lfs_server | gzip -9 - > lfs_server-${VERSION}-osx.x64.tar.gz

