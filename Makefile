test: c go python java

go:
	GOPATH=`pwd` go test -v objecthash.go objecthash_test.go

python:
	python objecthash_test.py

c: objecthash_test
	./objecthash_test

java:
	sbt compile
	sbt test

objecthash_test: objecthash_test.c objecthash.c
	cc -Wall -Werror -I/usr/local/include -o objecthash_test objecthash_test.c objecthash.c crypto-algorithms/sha256.c -L/usr/local/lib -ljson-c

get:
	GOPATH=`pwd` go get golang.org/x/text/unicode/norm
