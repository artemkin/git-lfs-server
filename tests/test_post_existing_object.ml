#!/usr/bin/env ocaml

#use "test.ml"

let request = {|
POST /objects HTTP/1.1
Host: localhost
Accept: application/vnd.git-lfs+json
Content-Type: application/vnd.git-lfs+json
Content-Length: 95

{
"oid" : "ebdaa749534bbbf8e1fc02c4f634648d749d5401e09b11fefbe283fe913b7d39",
"size" : 4090
}

|}

let response = {|
HTTP/1.1 200 OK
connection: keep-alive
content-length: 169
content-type: application/vnd.git-lfs+json

{
  "_links": {
    "download": {
      "href":
        "http://localhost:8080/data/objects/ebdaa749534bbbf8e1fc02c4f634648d749d5401e09b11fefbe283fe913b7d39"
    }
  }
}
|}

let () =
  Test.netcat request response


