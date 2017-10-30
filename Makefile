.PHONY: test go python c java go_deps

test: c go python java

go: go_deps
	GOPATH=`pwd` go test -v \
				 go/objecthash/objecthash.go \
				 go/objecthash/objecthash_test.go

python:
	python objecthash_test.py

c: objecthash_test
	./objecthash_test

java:
	sbt compile
	sbt test

objecthash_test: libobjecthash.so objecthash_test.c
	$(CC) -std=c99 -Wall -Werror -o objecthash_test objecthash_test.c -lobjecthash -L. -Wl,-rpath -Wl,.

libobjecthash.so: objecthash.c
	$(CC) -fPIC -shared -std=c99 -Wall -Werror -o libobjecthash.so objecthash.c -lcrypto `pkg-config --libs --cflags icu-uc json-c`

go_deps:
	GOPATH=`pwd` go get golang.org/x/text/unicode/norm
