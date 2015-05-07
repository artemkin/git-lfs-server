#!/usr/bin/env ocaml

#use "test.ml"

let request = {|
POST /objects HTTP/1.1
Host: localhost
Accept: application/vnd.git-lfs+json
Content-Type: application/vnd.git-lfs+json
Content-Length: 95

{
"oid" : "73BCC5E2FDB23B560E112BE22C901379BF9CE3A1F9CA32ACD92BC6BA5667A0AE",
"size" : 7170
}

|}

let response = {|
HTTP/1.1 400 Bad Request
connection: keep-alive
content-length: 29
content-type: application/vnd.git-lfs+json

{ "message": "Invalid body" }
|}

let () =
  Test.netcat request response

