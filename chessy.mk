# Local config to override default variables
include $(CHESSY_ROOT)/local.mk

# Submodules
CHESHIRE_ROOT ?= $(realpath $(CHESSY_ROOT)/sw/cheshire)
MESSY_ROOT    ?= $(realpath $(CHESSY_ROOT)/sw/messy)
OPENOCD_ROOT  ?= $(realpath $(CHESSY_ROOT)/sw/openocd)

# Tools
VIVADO   ?= vivado
OpenOCD  ?= openocd
RV64_GDB ?= riscv64-unknown-elf-gdb
DOCKER   ?= docker
PYTHON   ?= python3

# Variables
BIN ?= semihost_helloworld.spm.elf
GDB_ARGS ?=
GDB_PORT ?= 3334
INTER ?= 0
DATASET_GEN_SAMPLES ?= 10

CHESHIRE_TEST_DIR ?= $(CHESHIRE_ROOT)/sw/tests
CHESHIRE_TEST_BIN ?= $(CHESHIRE_TEST_DIR)/$(BIN)


##@ General

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} \
	/^[a-zA-Z_0-9-]+:.*?##/ { \
		printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 \
	} \
	/^##@/ { \
		printf "\n\033[1m%s\033[0m\n", substr($$0, 5) \
	}' $(MAKEFILE_LIST)

.PHONY: stop-all
stop-all: ## Stop all running components.
	$(MAKE) oocd-stop
	$(MAKE) chs-stop

.PHONY: clean
clean: ## Clean tmp and log files.
	@rm -rf $(CHESSY_ROOT)/tmp $(CHESSY_ROOT)/log && \
	echo "Temporary files cleaned."

.PHONY: clean-all
clean-all: ## Clean all build artifacts.
	@cd $(CHESHIRE_ROOT) && $(MAKE) clean
	@cd $(MESSY_ROOT) && $(MAKE) clean
	@cd $(OPENOCD_ROOT) && $(MAKE) clean
	$(MAKE) clean


##@ Messy

.PHONY: messy-docker-build
messy-docker-build: ## Build Docker image for Messy.
	@cd $(MESSY_ROOT) && \
	$(DOCKER) build . \
		-f docker/cheshire/Dockerfile \
		-t messy \
		--build-arg USER_ID=$(shell id -u $(USER)) \
		--build-arg GROUP_ID=$(shell id -g $(USER));

.PHONY: messy-docker-run
messy-docker-run: ## Run Messy Docker container.
	@if ! $(DOCKER) images | grep -q "^messy "; then \
		echo "Messy Docker image not found."; exit 1; \
	fi
	@$(DOCKER) run -it --rm \
		-v $(MESSY_ROOT):/messy \
		-v $(CHESHIRE_ROOT)/sw/tests:/tests \
		--network=host \
		--user root \
		messy || true


##@ Cheshire

.PHONY: chs-build
chs-build: ## Build Cheshire tests.
	@cd $(CHESHIRE_ROOT) && $(MAKE) chs-sw-all

.PHONY: chs-clean
chs-clean: ## Clean Cheshire build.
	@cd $(CHESHIRE_ROOT) && $(MAKE) clean


##@ GDB

.PHONY: gdb-start
gdb-start: ## Start Cheshire test through GDB. Possible args: BIN=<filename>, GDB_ARGS=<args>.
	@if ! command -v $(RV64_GDB) >/dev/null 2>&1; then \
		echo "RV64 GDB not found."; exit 1; fi
	@if [ ! -f "$(CHESHIRE_TEST_BIN)" ]; then \
		echo "Cheshire test binary not found: $(CHESHIRE_TEST_BIN)"; exit 1; fi
	@mkdir -p $(CHESSY_ROOT)/log
	@$(RV64_GDB) $(GDB_ARGS) -ex "target extended-remote localhost:$(GDB_PORT)" \
		-ex "file $(CHESHIRE_TEST_BIN)" \
		-ex "load"

.PHONY: gdb-stop
gdb-stop: ## Stop the GDB process.
	@pkill -u $(USER) -9 $(RV64_GDB) || true && \
	echo "Cheshire GDB process killed."


##@ OpenOCD

.PHONY: oocd-build
oocd-build: ## Build OpenOCD binaries.
	@cd $(OPENOCD_ROOT) && ./bootstrap && ./configure --enable-ftdi && $(MAKE) -j$(shell nproc)

.PHONY: oocd-start
oocd-start: ## Start OpenOCD.
	@if [ ! -x "$(OPENOCD_ROOT)/src/$(OpenOCD)" ]; then \
		echo "Build OpenOCD first."; exit 1; fi
	@mkdir -p $(CHESSY_ROOT)/log
	@$(OPENOCD_ROOT)/src/$(OpenOCD) -f $(CHESSY_ROOT)/sw/utils/zcu102.cfg

.PHONY: oocd-stop
oocd-stop: ## Kill all OpenOCD process if running.
	@pkill -u $(USER) -9 $(OpenOCD) || true && \
	echo "OpenOCD processes killed."

.PHONY: oocd-clean
oocd-clean: ## Clean OpenOCD build.
	@cd $(OPENOCD_ROOT) && $(MAKE) clean


##@ Utilities

.PHONY: dataset-generate
dataset-generate: ## Generate gesture sensor dataset file. Possible args: DATASET_GEN_SAMPLES=<num_samples>.
	@cd $(CHESSY_ROOT)/sw/utils && \
	$(PYTHON) generate_dataset.py $(DATASET_GEN_SAMPLES) && \
	mv dataset.bin $(CHESSY_ROOT)/sw/messy/messy/input_files/gesture/gesture_dataset.bin && \
	echo "Dataset generated at $(CHESSY_ROOT)/sw/messy/messy/input_files/gesture/gesture_dataset.bin"

.PHONY: board-flash
board-flash: ## Flash the board.
	@mkdir -p $(CHESSY_ROOT)/tmp
	@cd $(CHESSY_ROOT)/tmp && $(VIVADO) -mode batch -source $(CHESSY_ROOT)/hw/scripts/flash_board.tcl

.PHONY: board-flash-clean
board-flash-clean: ## Clean temporary files after flashing the board.
	@rm -rf $(CHESSY_ROOT)/tmp

.PHONY: board-uart
board-uart: ## Start the UART adapter.
	@$(PYTHON) $(CHESSY_ROOT)/hw/scripts/uart_adapter_host.py

.PHONY: board-uart-stop
board-uart-stop: ## Stop the UART adapter.
	@pkill -u $(USER) -9 -x -f "$(CHESSY_ROOT)/hw/scripts/uart_adapter_host.py" || true && \
	echo "UART adapter process killed."
