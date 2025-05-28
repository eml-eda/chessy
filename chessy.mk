
## Submodules
CHESHIRE_ROOT ?= $(realpath $(CHESSY_ROOT)/sw/cheshire)
MESSY_ROOT    ?= $(realpath $(CHESSY_ROOT)/sw/messy)
OPENOCD_ROOT  ?= $(realpath $(CHESSY_ROOT)/sw/openocd)

# Tools
VIVADO   ?= vivado
OpenOCD  ?= openocd
RV64_GDB ?= riscv64-unknown-elf-gdb

# Variables TODO: Make these configurable
CHESHIRE_TEST_DIR ?= $(CHESSY_ROOT)/sw/cheshire/sw/tests
CHESHIRE_TEST_BIN ?= /home/zcu102/git/cheshire/sw/tests/semihost_file.spm.elf

##@ General

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: submodules
submodules: ## Update all submodules.
	@echo "Updating submodules..."
	@git submodule update --init --recursive
	@echo "Submodules updated."

.PHONY: clean
clean: ## Clean tmp and log files.
	@rm -rf $(CHESSY_ROOT)/tmp && \
	@rm -rf $(CHESSY_ROOT)/log && \
	echo "Temporary files cleaned."

.PHONY: clean-all
clean-all: ## Clean all build artifacts.
	@echo "Cleaning Cheshire build artifacts..."
	@cd $(CHESHIRE_ROOT) && \
	$(MAKE) clean
	@echo "Cleaning Messy build artifacts..."
	@cd $(MESSY_ROOT) && \
	$(MAKE) clean
	@echo "Cleaning OpenOCD build artifacts..."
	@cd $(OPENOCD_ROOT) && \
	$(MAKE) clean
	@echo "All build artifacts cleaned."


##@ Software

.PHONY: sw-chs-build
sw-chs-build: ## Build Cheshire tests.
	@cd $(CHESHIRE_ROOT) && \
	$(MAKE) chs-sw-all

.PHONY: sw-chs-start
sw-chs-start: ## Start Cheshire test through GDB in the background.
	@if ! command -v $(RV64_GDB) >/dev/null 2>&1; then \
		echo "RV64 GDB not found, please install riscv64-unknown-elf-gdb."; \
		exit 1; \
	fi && \
	if [ ! -f "$(CHESHIRE_TEST_BIN)" ]; then \
		echo "Cheshire test binary not found, please build it first with '$(MAKE) sw-chs-build'."; \
		exit 1; \
	fi && \
	mkdir -p $(CHESSY_ROOT)/log && \
	$(RV64_GDB) -ex "set confirm off" \
				-ex "target extended-remote localhost:3333" \
				-ex "set confirm off" \
				-ex "file $(CHESHIRE_TEST_BIN)" \
				-ex "load" \
				-ex "continue" \
				> $(CHESSY_ROOT)/log/cheshire.log 2>&1 & \
	echo "Cheshire test started in the background, check $(CHESSY_ROOT)/log/cheshire.log."
	
.PHONY: sw-chs-stop
sw-chs-stop: ## Kill all GDB processes if running.
	@pkill -u $(USER) -9 -f "$(RV64_GDB).*$(CHESHIRE_TEST_BIN)" && \
	echo "GDB process killed."

.PHONY: sw-chs-clean
sw-chs-clean: ## Clean Cheshire build files.
	@cd $(CHESHIRE_ROOT) && \
	$(MAKE) clean && \
	echo "Cheshire build files cleaned."

.PHONY: sw-oocd-build
sw-oocd-build: ## Build the OpenOCD binaries.
	@cd $(OPENOCD_ROOT) && \
	./bootstrap && \
	./configure --enable-ftdi && \
	$(MAKE) -j$(shell nproc) && \
	if [ ! -x "$(OPENOCD_ROOT)/src/$(OpenOCD)" ]; then \
		echo "OpenOCD binaries not found, build failed."; \
		exit 1; \
	else \
		echo "OpenOCD binaries built successfully."; \
	fi

.PHONY: sw-oocd-start
sw-oocd-start: ## Start OpenOCD for Cheshire in the background.
	@if [ ! -x "$(OPENOCD_ROOT)/src/$(OpenOCD)" ]; then \
		echo "OpenOCD binaries not found, to build them run '$(MAKE) sw-oocd-build'"; \
	else \
		mkdir -p $(CHESSY_ROOT)/log && \
		nohup $(OPENOCD_ROOT)/src/$(OpenOCD) -f $(CHESSY_ROOT)/sw/utils/zcu102.cfg > $(CHESSY_ROOT)/log/openocd.log 2>&1 & \
		echo "OpenOCD started in the background, check $(CHESSY_ROOT)/log/openocd.log."; \
	fi

.PHONY: sw-oocd-stop
sw-oocd-stop: ## Kill all OpenOCD process if running.
	@pkill -u $(USER) -9 $(OpenOCD) && \
	echo "OpenOCD processes killed."

.PHONY: sw-oocd-clean
sw-oocd-clean: ## Clean up OpenOCD build files.
	@cd $(OPENOCD_ROOT) && \
	$(MAKE) clean && \
	echo "OpenOCD build files cleaned."


##@ Hardware

.PHONY: hw-check-connections
# TODO:hw-check-connections: ## Check whether all the connections with the board are working.
	@:

.PHONY: hw-flash
hw-flash: ## Flash the board with the Cheshire binary.
	@mkdir -p $(CHESSY_ROOT)/tmp && \
	cd $(CHESSY_ROOT)/tmp && \
	$(VIVADO) -mode batch -source $(CHESSY_ROOT)/hw/scripts/flash_board.tcl && \
	echo "Flashing completed."

.PHONY: hw-flash-clean
hw-flash-clean: ## Clean up temporary files after flashing the board.
	@rm -rf $(CHESSY_ROOT)/tmp
