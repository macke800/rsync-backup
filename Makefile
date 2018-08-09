DOCKER ?= docker
DOCKER_CONFIG = ./Dockerfile
DOCKER_IMAGE = rsync-backup-testenv
DOCKER_INSTANCE = rsync-backup-testenv-instance

BATS_BIN_PATH = ../bats-core/bin

all: test

test: $(DOCKER_CONFIG)
	@$(DOCKER) build -t $(DOCKER_IMAGE) .
	@$(DOCKER) run -l "error" --name $(DOCKER_INSTANCE) $(DOCKER_IMAGE)
	@$(DOCKER) rm $(DOCKER_INSTANCE)

clean:
	@if ! [ -z "$(shell $(DOCKER) ps -f name=$(DOCKER_INSTANCE) -q)" ]; then \
		echo "--- Removing docker test instance"; \
		$(DOCKER) -l "error" kill $(DOCKER_INSTANCE); \
		$(DOCKER) -l "error" rm $(DOCKER_INSTANCE); \
	fi


.PHONY: all test clean
