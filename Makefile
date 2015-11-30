INSTALL_PREFIX ?= /usr/local
CPPFLAGS ?= -I/usr/local/include
CFLAGS ?= -Wall -Werror
LDFLAGS ?= -L/usr/local/lib

all: objecthash.a

%.c%.a:
	$(CC) -c $(CFLAGS) $<
	$(AR) $(ARFLAGS) $@ $*.o

objecthash.a: objecthash.a(objecthash.o) objecthash.a(crypto-algorithms/sha256.o)

install:
	mkdir -p $(INSTALL_PREFIX)/lib
	mkdir -p $(INSTALL_PREFIX)/include
	mkdir -p $(INSTALL_PREFIX)/include/crypto-algorithms
	cp objecthash.a $(INSTALL_PREFIX)/lib
	cp objecthash.h $(INSTALL_PREFIX)/include
	cp crypto-algorithms/sha256.h $(INSTALL_PREFIX)/include/crypto-algorithms

test: c go java python

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
	$(CC) $(CFLAGS) $(CPPFLAGS) -o objecthash_test objecthash_test.c objecthash.c crypto-algorithms/sha256.c $(LDFLAGS) -ljson-c

get:
	GOPATH=`pwd` go get golang.org/x/text/unicode/norm
