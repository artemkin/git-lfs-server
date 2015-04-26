#!/bin/sh

PREFIX=$(dirname $(dirname $0))

export DYLD_LIBRARY_PATH=${PREFIX}/lib

if [ -f ${PREFIX}/bin/lfs_server ]; then
  ${PREFIX}/bin/lfs_server $@
else
  echo "No Git LFS server installed"
fi

