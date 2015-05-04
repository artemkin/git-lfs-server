
time curl -X PUT http://127.0.0.1:8080/objects/$1 --upload-file $2
time curl -O http://127.0.0.1:8080/data/objects/$1

