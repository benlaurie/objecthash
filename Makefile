CPPFLAGS ?= -I/usr/local/include
LDFLAGS ?= -L/usr/local/lib

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
	$(CC) -Wall -Werror $(CPPFLAGS) -o objecthash_test objecthash_test.c objecthash.c $(LDFLAGS) -ljson-c -lcrypto

get:
	GOPATH=`pwd` go get golang.org/x/text/unicode/norm
