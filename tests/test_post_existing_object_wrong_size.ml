#!/usr/bin/env ocaml

#use "test.ml"

let request = {|
POST /objects HTTP/1.1
Host: localhost
Accept: application/vnd.git-lfs+json
Content-Type: application/vnd.git-lfs+json
Content-Length: 96

{
"oid" : "ebdaa749534bbbf8e1fc02c4f634648d749d5401e09b11fefbe283fe913b7d39",
"size" : 12345
}

|}

let response = {|
HTTP/1.1 400 Bad Request
connection: keep-alive
content-length: 34
content-type: application/vnd.git-lfs+json

{ "message": "Wrong object size" }
|}

let () =
  Test.netcat request response

