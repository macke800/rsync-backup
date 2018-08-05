DOCKER ?= docker
DOCKER_CONFIG = ./Dockerfile
DOCKER_IMAGE = rsync-backup-testenv
DOCKER_INSTANCE = rsync-backup-testenv-instance

BATS_BIN_PATH = ../bats-core/bin

TEST_DATA_PATH = ./test/test-data
TEST_DATA = $(TEST_DATA_PATH)/5MB-file.bin $(TEST_DATA_PATH)/subfolder/2MB-file.bin

all: test

create-env: $(DOCKER_CONFIG)
	@$(DOCKER) build -l "error" -t $(DOCKER_IMAGE) .

$(TEST_DATA):
	@mkdir -p ./test/test-data/subfolder
	@dd if=/dev/zero of=./test/test-data/5MB-file.bin bs=1M count=10
	@dd if=/dev/zero of=./test/test-data/subfolder/2MB-file.bin bs=1M count=2

start-env: clean
	@$(DOCKER) run -d -l "error" -p 2020:22 --name $(DOCKER_INSTANCE) $(DOCKER_IMAGE) >> /dev/null 2>&1

test: start-env $(TEST_DATA)
	@echo ""
	@echo "----- Start test(s) ------"
	export PATH=$$PATH:$(BATS_BIN_PATH); echo $$PATH; bats -r ./test
	@echo "----- End test(s) ------"
	@echo ""

clean:
	@if ! [ -z "$(shell $(DOCKER) ps -f name=$(DOCKER_INSTANCE) -q)" ]; then \
		echo "--- Removing docker test instance"; \
		$(DOCKER) -l "error" kill $(DOCKER_INSTANCE); \
		$(DOCKER) -l "error" rm $(DOCKER_INSTANCE); \
	fi
	@if [ -d "$(TEST_DATA_PATH)" ]; then \
		echo "--- Removing test data"; \
		rm -rf $(TEST_DATA_PATH); \
	fi


.PHONY: all test clean create-env start-env
