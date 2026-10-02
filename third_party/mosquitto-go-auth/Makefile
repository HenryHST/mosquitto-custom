# Prefer Mosquitto headers from source install (/usr/local) or distro packages (/usr).
CFLAGS := -I/usr/local/include -I/usr/include -fPIC
LDFLAGS := -shared -fuse-ld=bfd -Wl,-unresolved-symbols=ignore-all

UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S),Darwin)
	# macOS: prefer Homebrew includes when present; keep dynamic_lookup for Mosquitto ABI
	CFLAGS := -I/usr/local/include -I/opt/homebrew/include -fPIC
	LDFLAGS := -shared -undefined dynamic_lookup
endif

all:
	@echo "Building for $(UNAME_S)"
	env CGO_CFLAGS="$(CFLAGS)" go build -buildmode=c-archive go-auth.go
	env CGO_LDFLAGS="$(LDFLAGS)" go build -buildmode=c-shared -o go-auth.so
	go build -o pw pw-gen/pw.go

without-vcs:
	@echo "Building for $(UNAME_S)"
	env CGO_CFLAGS="$(CFLAGS)" go build -buildvcs=false -buildmode=c-archive go-auth.go
	env CGO_LDFLAGS="$(LDFLAGS)" go build -buildvcs=false -buildmode=c-shared -o go-auth.so
	go build -buildvcs=false -o pw pw-gen/pw.go

test:
	cd plugin && make
	go test ./backends ./cache ./hashing -v -count=1 -buildvcs=false
	rm plugin/*.so

test-backends:
	cd plugin && make
	go test ./backends -v -failfast -count=1
	rm plugin/*.so

test-cache:
	go test ./cache -v -failfast -count=1

test-hashing:
	go test ./hashing -v -failfast -count=1

build-docker-test:
	docker build -t mosquitto-go-auth.test -f Dockerfile.runtest .

run-docker-test:
	docker run --rm -ti mosquitto-go-auth.test ./run-test-in-docker.sh

service:
	@echo "Generating gRPC code from .proto files"
	@go generate grpc/grpc.go

clean:
	rm -f go-auth.h
	rm -f go-auth.so
	rm -f pw
