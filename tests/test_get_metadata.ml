#!/usr/bin/env ocaml unix.cma

#use "test.ml"

let request = {|
GET /objects/ebdaa749534bbbf8e1fc02c4f634648d749d5401e09b11fefbe283fe913b7d39 HTTP/1.1
Host: localhost

|}

let response = {|
HTTP/1.1 200 OK
connection: keep-alive
content-length: 402
content-type: application/vnd.git-lfs+json

{
  "oid": "ebdaa749534bbbf8e1fc02c4f634648d749d5401e09b11fefbe283fe913b7d39",
  "size": 4090,
  "_links": {
    "self": {
      "href":
        "http://localhost:8080/objects/ebdaa749534bbbf8e1fc02c4f634648d749d5401e09b11fefbe283fe913b7d39"
    },
    "download": {
      "href":
        "http://localhost:8080/data/objects/ebdaa749534bbbf8e1fc02c4f634648d749d5401e09b11fefbe283fe913b7d39"
    }
  }
}
|}

let () =
  run request response

