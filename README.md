
# Git LFS server

Simple HTTP server for [Git Large File Storage](https://git-lfs.github.com).

```
$ ./lfs_server -help

Start Git LFS server

  lfs_server [ROOT]

=== flags ===

  [-p port]      TCP port to listen on
  [-s address]   IP address to listen on
  [-build-info]  print info about this build and exit
  [-version]     print the version of this build and exit
  [-help]        print this help text and exit
                 (alias: -?)
```
By default, it starts on `http://localhost:8080` and treats current directory as `ROOT`. All object files are stored locally in `ROOT/.lfs/objects` directory.

## TODO
* ~~HTTPS support (trivial to add)~~
* Authentication
* Upload validation (calculate SHA-256 digest)
* ~~Speed-up uploading~~ (fixed in `cohttp`, see [#330](https://github.com/mirage/ocaml-cohttp/pull/330))
* Multi server support
* Automated tests
