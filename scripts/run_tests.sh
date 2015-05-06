#!/bin/sh

set -e

echo Build from scratch
rm -rf .lfs
ocamlbuild -clean
./scripts/test_build.sh src/lfs_server.native

echo Copy test .lfs folder
cp -R tests/.lfs .

echo Run server
export BISECT_FILE=_build/coverage
./lfs_server.native -verbose &
LFS_SERVER_PID=$!
sleep 2

echo Run tests
cd tests
find . -iname '*.ml' -exec '{}' \;

echo Stop server
kill $LFS_SERVER_PID
sleep 2

echo Generate code coverage report
cd ../_build
bisect-report -html report coverage*.out
cd ..

