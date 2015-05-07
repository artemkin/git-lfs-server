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

echo Test GET method
./test_get_metadata.ml
./test_get_object.ml
./test_get_uppercase_oid_rejected.ml

echo Test HEAD method
./test_head_metadata.ml
./test_head_object.ml

./test_method_not_allowed.ml
./test_no_host.ml

echo Test POST method
./test_post_empty_json.ml
./test_post_existing_object.ml
./test_post_existing_object_wrong_size.ml
./test_post_new_object.ml
./test_post_uppercase_oid_rejected.ml

echo Test PUT method
./test_put_1_new_file_wrong_content.ml
./test_put_2_new_file_correct_content.ml
./test_put_3_existing_file.ml

echo Stop server
kill $LFS_SERVER_PID
sleep 2

echo Generate code coverage report
cd ../_build
bisect-report -html report coverage*.out
cd ..

