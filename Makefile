.PHONY: test go_test ruby python c java go_deps

PKG_CONFIG_PATH=/usr/local/opt/icu4c/lib/pkgconfig

test: c ruby go_test python java

go_test: go_deps
	GOPATH=`pwd` go test -timeout 1m -v go/objecthash/objecthash.go go/objecthash/objecthash_test.go

ruby:
	cd ruby && rake

python:
	python objecthash_test.py

c: objecthash_test
	./objecthash_test

java:
	sbt compile
	sbt test

objecthash_test: libobjecthash.so objecthash_test.c
	$(CC) -std=c99 -Wall -Werror -Wextra -o objecthash_test objecthash_test.c -lobjecthash -L. -Wl,-rpath -Wl,. `pkg-config --libs --cflags icu-uc json-c openssl`

libobjecthash.so: objecthash.c
	$(CC) -fPIC -shared -std=c99 -Wall -Werror -Wextra -o libobjecthash.so objecthash.c -lcrypto `pkg-config --libs --cflags icu-uc json-c openssl`

go_deps:
	GOPATH=`pwd` go get golang.org/x/text/unicode/norm
