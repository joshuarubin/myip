ALL_DIRS=$(shell find . \( -path ./Godeps -o -path ./vendor -o -path ./.git \) -prune -o -type d -print)
EXECUTABLE=myip
DOCKER_DIR=Docker
DOCKER_FILE=$(DOCKER_DIR)/Dockerfile
GO_FILES=$(foreach dir, $(ALL_DIRS), $(wildcard $(dir)/*.go))

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

.PHONY: all build clean save image
