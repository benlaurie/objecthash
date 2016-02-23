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

objecthash_test: libobjecthash.so
	$(CC) -std=c99 -Wall -Werror -o objecthash_test objecthash_test.c -lobjecthash -L. -Wl,-rpath -Wl,.

libobjecthash.so: objecthash.c
	$(CC) -fPIC -shared -std=c99 -Wall -Werror -o libobjecthash.so objecthash.c -lcrypto `pkg-config --libs --cflags icu-uc json-c`

get:
	GOPATH=`pwd` go get golang.org/x/text/unicode/norm
