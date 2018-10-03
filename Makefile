DOCKER ?= docker
DOCKER_CONFIG = ./Dockerfile
DOCKER_IMAGE = rsync-backup-testenv
DOCKER_INSTANCE = rsync-backup-testenv-instance

BATS_BIN_PATH = ../bats-core/bin

BUILD_FOLDER = build
VERSION_FULL = $(shell dpkg-parsechangelog --show-field Version)
VERSION = $(subst -1,"",$(VERSION_FULL))
PKG_NAME = rsync-backup
PKG_BUILD_FOLDER = $(BUILD_FOLDER)/package/$(PKG_NAME)-$(VERSION)
PKG_ORIG_TAR = $(PKG_NAME)_$(VERSION).orig.tar.xz
SRC_FILES = $(wildcard src/*)
DST_FILES = $(patsubst src/%,$(PKG_BUILD_FOLDER)/%,$(SRC_FILES))

all: test

test: shellcheck clean run_tests

shellcheck:
	@(cd src && shellcheck -x *.sh)

run_tests: $(DOCKER_CONFIG)
	@$(DOCKER) build -t $(DOCKER_IMAGE) .
	@$(DOCKER) run -l "error" --name $(DOCKER_INSTANCE) $(DOCKER_IMAGE)
	@$(DOCKER) rm $(DOCKER_INSTANCE)

clean:
	@if ! [ -z "$(shell $(DOCKER) ps -f name=$(DOCKER_INSTANCE) -q --all)" ]; then \
		echo "--- Removing docker test instance"; \
		$(DOCKER) -l "error" kill $(DOCKER_INSTANCE); \
		$(DOCKER) -l "error" rm $(DOCKER_INSTANCE); \
	fi
	@rm -rf $(BUILD_FOLDER)

$(PKG_BUILD_FOLDER): 
	@mkdir -p $@

$(DST_FILES): $(PKG_BUILD_FOLDER)
	@cp $(SRC_FILES) $(PKG_BUILD_FOLDER)

$(PKG_BUILD_FOLDER)/debian: $(PKG_BUILD_FOLDER)
	@cp -R ./debian $(PKG_BUILD_FOLDER)/

$(PKG_ORIG_TAR): $(DST_FILES)
	@(cd $(PKG_BUILD_FOLDER) && tar cJvf ../$(PKG_ORIG_TAR) $(patsubst $(PKG_BUILD_FOLDER)/%,./%,$(DST_FILES)))

package: test $(DST_FILES) $(PKG_BUILD_FOLDER)/debian $(PKG_ORIG_TAR)
	@(cd $(PKG_BUILD_FOLDER) && debuild -us -uc)
	@cp $(PKG_BUILD_FOLDER)/../$(PKG_NAME)_$(VERSION_FULL)_all.deb $(BUILD_FOLDER)

.PHONY: all shellcheck test clean run_tests 
