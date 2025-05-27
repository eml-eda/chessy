
##@ General

## Submodules
CHESHIRE_ROOT ?= $(realpath ${CHESSY_ROOT}/sw/cheshire)
MESSY_ROOT    ?= $(realpath ${CHESSY_ROOT}/sw/messy)
OPENOCD_ROOT  ?= $(realpath ${CHESSY_ROOT}/sw/openocd)

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Software

.PHONY: sw-build
sw-build: ## Build Cheshire tests.
	cd ${CHESHIRE_ROOT} && \
	make chs-sw-all

##@ Hardware

VIVADO ?= vivado

.PHONY: hw-check-connections
# TODO:hw-check-connections: ## Check whether all the connections with the board are working.
	@:

.PHONY: hw-flash
hw-flash: ## Flash the board with the Cheshire binary.
	# Move to a temporary directory to run Vivado
	mkdir -p ${CHESSY_ROOT}/tmp
	cd ${CHESSY_ROOT}/tmp && \
	${VIVADO} -mode batch -source ${CHESSY_ROOT}/hw/scripts/flash_board.tcl

.PHONY: hw-flash-clean
hw-flash-clean: ## Clean up temporary files after flashing the board.
	rm -rf ${CHESSY_ROOT}/tmp

