
# Copyright (c) 2018 Huawei Technologies Co., Ltd. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# for testing Travis

BASE_DIR := $(shell pwd)
BUILD_DIR := $(BASE_DIR)/build/out
DIST_DIR := $(BASE_DIR)/build/dist
VERSION ?= $(shell git describe --exact-match 2> /dev/null || \
                 git describe --match=$(git rev-parse --short=8 HEAD) \
		 --always --dirty --abbrev=8)
BUILD_TGT := opensds-hotpot-$(VERSION)-linux-amd64

all: build

ubuntu-dev-setup:
	sudo apt-get update && sudo apt-get install -y \
	  build-essential gcc librados-dev librbd-dev

build:osdsdock osdslet osdsctl osds_verify osds_unit_test osds_integration_test osds_e2eflowtest_build osds_e2etest_build 

prebuild:
	mkdir -p $(BUILD_DIR)

.PHONY: osdsdock osdslet osdsctl docker test protoc






osdsdock: prebuild
	go build -o $(BUILD_DIR)/bin/osdsdock github.com/opensds/opensds/cmd/osdsdock

osdslet: prebuild
	go build -o $(BUILD_DIR)/bin/osdslet github.com/opensds/opensds/cmd/osdslet

osdsctl: prebuild
	go build -o $(BUILD_DIR)/bin/osdsctl github.com/opensds/opensds/osdsctl

docker: build
	cp $(BUILD_DIR)/bin/osdsdock ./cmd/osdsdock
	cp $(BUILD_DIR)/bin/osdslet ./cmd/osdslet
	docker build cmd/osdsdock -t opensdsio/opensds-dock:latest
	docker build cmd/osdslet -t opensdsio/opensds-controller:latest

test: build
	script/CI/test


###### Added by Satya #####

# make osds_core
.PHONY: osds_core
osds_core:
	cd osds && $(MAKE)

# unit tests
.PHONY: osds_unit_test
osds_unit_test:
	cd osds && $(MAKE) test

# verify
.PHONY: osds_verify
osds_verify:
	cd osds && $(MAKE) verify

.PHONY: osds_integration_test
osds_integration_test:
	cd osds && $(MAKE) integration_test

.PHONY: osds_e2etest_build
osds_e2etest_build:
	cd osds && $(MAKE) e2etest_build

.PHONY: osds_e2eflowtest_build
osds_e2eflowtest_build:
	cd osds && $(MAKE) e2eflowtest_build



###### End Added by Satya #####
protoc:
	cd pkg/dock/proto && protoc --go_out=plugins=grpc:. dock.proto

clean:
	rm -rf $(BUILD_DIR) ./cmd/osdslet/osdslet ./cmd/osdsdock/osdsdock

version:
	@echo ${VERSION}

.PHONY: dist
dist: build
	( \
	    rm -fr $(DIST_DIR) && mkdir $(DIST_DIR) && \
	    cd $(DIST_DIR) && \
	    mkdir $(BUILD_TGT) && \
	    cp -r $(BUILD_DIR)/bin $(BUILD_TGT)/ && \
	    cp $(BASE_DIR)/LICENSE $(BUILD_TGT)/ && \
	    zip -r $(DIST_DIR)/$(BUILD_TGT).zip $(BUILD_TGT) && \
	    tar zcvf $(DIST_DIR)/$(BUILD_TGT).tar.gz $(BUILD_TGT) && \
	    tree \
	)
