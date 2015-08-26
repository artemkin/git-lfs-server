
# Git LFS server

[![Build Status](https://travis-ci.org/artemkin/git-lfs-server.svg?branch=master)](https://travis-ci.org/artemkin/git-lfs-server)
[![Coverage Status](https://coveralls.io/repos/artemkin/git-lfs-server/badge.png?branch=master)](https://coveralls.io/r/artemkin/git-lfs-server?branch=master)

Simple HTTP(S) server for [Git Large File Storage](https://git-lfs.github.com).

```
$ ./lfs_server -help
Start Git LFS server

  lfs_server [ROOT]

=== flags ===

  [-cert file]   File of certificate for https
  [-key file]    File of private key for https
  [-p port]      TCP port to listen on
  [-s address]   IP address to listen on
  [-verbose]     Verbose logging
  [-build-info]  print info about this build and exit
  [-version]     print the version of this build and exit
  [-help]        print this help text and exit
                 (alias: -?)
```
By default, it starts on `http://localhost:8080` and treats current directory as `ROOT`. All object files are stored locally in `ROOT/.lfs/objects` directory.

## INSTALL

From binary packages:
* [Linux x64](https://github.com/artemkin/git-lfs-server/releases/download/v0.2.2/lfs_server-0.2.2-linux.x64.tar.gz)
* [Mac OS X x64](https://github.com/artemkin/git-lfs-server/releases/download/v0.2.2/lfs_server-0.2.2-osx.x64.tar.gz)

## TODO
* Multi server support
* Create OPAM package
* Add max file size option
* Add connection timeouts
* Authentication
* ~~Automated tests~~
* ~~Setup Travis continuous builds~~
* ~~Setup Coverals~~
* ~~Remove incomplete/broken temporary files~~
* ~~Upload validation (calculate SHA-256 digest)~~
* ~~Reject uppercase SHA-256 hex digests~~
* ~~Fix HTTPS urls~~
* ~~Rearrange files in release package and remove redundant libs~~
* ~~Add logging~~
* ~~Check SIGQUIT and SIGINT are handled correctly~~
* ~~HTTPS support (trivial to add)~~
* ~~Speed-up uploading~~ (fixed in `cohttp`, see [#330](https://github.com/mirage/ocaml-cohttp/pull/330))

