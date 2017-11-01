test: c go_test python java

go_test:
	GOPATH=`pwd` go test -v go/objecthash/objecthash.go go/objecthash/objecthash_test.go

python:
	python objecthash_test.py

c: objecthash_test
	./objecthash_test

java:
# FIXME: sbt seems to not work with JDK 1.9.1
#	sbt compile
#	sbt test

objecthash_test: libobjecthash.so
	$(CC) -std=c99 -Wall -Werror -Wextra -o objecthash_test objecthash_test.c -lobjecthash -L. -Wl,-rpath -Wl,. `pkg-config --libs --cflags icu-uc json-c openssl`

libobjecthash.so: objecthash.c
	$(CC) -fPIC -shared -std=c99 -Wall -Werror -Wextra -o libobjecthash.so objecthash.c -lcrypto `pkg-config --libs --cflags icu-uc json-c openssl`

get:
	GOPATH=`pwd` go get golang.org/x/text/unicode/norm
