#!/bin/sh

set -e

echo Build from scratch
ocamlbuild -clean
./scripts/test_build.sh src/lfs_server.native

echo Run server
export BISECT_FILE=_build/coverage
./lfs_server.native -verbose &
sleep 2

echo Run tests
cd tests
find . -iname '*.ml' -exec '{}' \;

echo Stop server
kill %1
sleep 2

echo Generate code coverage report
cd ../_build
bisect-report -html report coverage*.out
cd ..

