ALL_DIRS=$(shell find . \( -path ./Godeps -o -path ./vendor -o -path ./.git \) -prune -o -type d -print)
EXECUTABLE=myip
DOCKER_DIR=Docker
DOCKER_FILE=$(DOCKER_DIR)/Dockerfile
GO_FILES=$(foreach dir, $(ALL_DIRS), $(wildcard $(dir)/*.go))
DOCKER_RELEASE_TAG=$(shell date +%Y%m%d-%H%M%S)
GOLANG_VERSION ?= 1.5.1

export GO15VENDOREXPERIMENT=1

all: build

build: $(EXECUTABLE)

$(EXECUTABLE): $(GO_FILES)
	go build -v -o $(EXECUTABLE)

clean:
	@rm -f $(EXECUTABLE) \
      $(DOCKER_DIR)/$(EXECUTABLE) \
      ./.image-stamp

save: .save-stamp

.save-stamp: $(GO_FILES)
	@rm -rf ./Godeps ./vendor
	GOOS=linux GOARCH=amd64 godep save ./...
	@touch .save-stamp

$(DOCKER_DIR)/$(EXECUTABLE): $(GO_FILES)
	@CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -v -tags netgo -installsuffix netgo -o $(DOCKER_DIR)/$(EXECUTABLE)

image: .image-stamp

.image-stamp: $(DOCKER_DIR)/$(EXECUTABLE) $(DOCKER_FILE)
	@rm -f $(DOCKER_FILE).bak
	docker build -t joshuarubin/$(EXECUTABLE) $(DOCKER_DIR)
	@touch .image-stamp

push:
	docker tag -f $(DOCKER_IMAGE):latest $(DOCKER_IMAGE):$(DOCKER_RELEASE_TAG)
	docker push $(DOCKER_IMAGE):latest
	docker push $(DOCKER_IMAGE):$(DOCKER_RELEASE_TAG)

$(HOME)/go/go$(GOLANG_VERSION).linux-amd64.tar.gz:
	@mkdir -p $(HOME)/go
	wget https://storage.googleapis.com/golang/go$(GOLANG_VERSION).linux-amd64.tar.gz -O $(HOME)/go/go$(GOLANG_VERSION).linux-amd64.tar.gz

$(HOME)/go/go$(GOLANG_VERSION)/bin/go: $(HOME)/go/go$(GOLANG_VERSION).linux-amd64.tar.gz
	@tar -C $(HOME)/go -zxf $(HOME)/go/go$(GOLANG_VERSION).linux-amd64.tar.gz
	@mv $(HOME)/go/go $(HOME)/go/go$(GOLANG_VERSION)
	@touch $(HOME)/go/go$(GOLANG_VERSION)/bin/go

install_go: $(HOME)/go/go$(GOLANG_VERSION)/bin/go

.PHONY: all build clean save image push install_go
