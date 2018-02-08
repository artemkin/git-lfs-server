
# Git LFS server

[![Build Status](https://travis-ci.org/artemkin/git-lfs-server.svg?branch=master)](https://travis-ci.org/artemkin/git-lfs-server)
[![Coverage Status](https://coveralls.io/repos/artemkin/git-lfs-server/badge.png?branch=master)](https://coveralls.io/r/artemkin/git-lfs-server?branch=master)

Simple HTTP(S) server for [Git Large File Storage](https://git-lfs.github.com) with [PAM](https://en.wikipedia.org/wiki/Pluggable_authentication_module) authentication.

```
$ ./lfs_server.sh -help
Start Git LFS server

  lfs_server [ROOT]

=== flags ===

  [-cert file]    File of certificate for https
  [-key file]     File of private key for https
  [-p port]       TCP port to listen on
  [-pam service]  PAM service name for user authentication
  [-s address]    IP address to listen on
  [-verbose]      Verbose logging
  [-build-info]   print info about this build and exit
  [-version]      print the version of this build and exit
  [-help]         print this help text and exit
                  (alias: -?)
```
By default, it starts on `http://localhost:8080` and treats current directory as `ROOT`. All object files are stored locally in `ROOT/.lfs/objects` directory.

## INSTALL

From binary packages:
* [Linux x64](https://github.com/artemkin/git-lfs-server/releases/download/v0.3.1/lfs_server-0.3.1-linux.x64.tar.gz)
* [Mac OS X x64](https://github.com/artemkin/git-lfs-server/releases/download/v0.3.0/lfs_server-0.3.0-osx.x64.tar.gz)



## RUN

**HTTP server without authentication**

```
./lfs_server.sh -verbose -s IP_ADDRESS -p PORT
```
A server will ignore credentials passed by LFS client, and accept all connections. To enable authentication, you need to specify PAM service.

**HTTP server with PAM authentication**
```
./lfs_server.sh -verbose -pam login -s IP_ADDRESS -p PORT
```
It will use built-in `login` PAM service defined in `/etc/pam.d/login` file.

Warning: LFS client uses HTTP basic authentication, so using **HTTPS** is a must!

**HTTPS server with PAM authentication**
```
./lfs_server.sh -verbose -pam login -s IP_ADDRESS -p PORT -cert domain.crt -key domain.key
```

## Example

Download and install the LFS server as described above. You will also need to install the [GIT LFS client](https://git-lfs.github.com/).

```
# Start a LFS server
./lfs_server.sh

# Clone a repo
git clone ....
cd repo

# Add a normal file
touch test.txt
git add test.txt
git commit -m "normal file"

# Add a lfs file 
git lfs install
dd if=/dev/zero of=test.bin count=10240 bs=1024   # Create a file which is 10MB
git lfs track test.bin
git add .gitattributes test.bin
git commit -m "lfs file"

# Configure lfs remote to local server
git config -f .lfsconfig lfs.url http://localhost:8080
git add .lfsconfig
git commit -m "lfs config"

# Push changes
git push
```

## TODO
* Multi server support
* Create OPAM package
* Add max file size option
* Add connection timeouts
* ~~Authentication~~
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

