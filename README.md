# ♟️ Chessy (Cheshire + Messy)

**Chessy** is a hardware-in-the-loop co-simulation framework that integrates the [Cheshire host platform](https://github.com/pulp-platform/cheshire), running on an FPGA, with the [Messy extra-functional simulator](https://github.com/eml-eda/messy), running on the host computer. This setup allows Messy to monitor and simulate extra-functional properties while Cheshire executes workloads in real hardware.

This repository contains the utilities to run Chessy, including the necessary scripts and configurations to set up the co-simulation environment.

## Platform

Chessy targets the **Xilinx ZCU102** FPGA development board to map the Cheshire system onto the programmable logic. However, the flow can be adapted to other platforms as well.

## 🚀 Quick Start

### 0. Prerequisites

Make sure you have the following tools installed:

- **RV64 GCC Toolchain**: _Required to compile programs for Cheshire_  
  Install the full toolchain from the official source: [https://github.com/riscv-collab/riscv-gnu-toolchain](https://github.com/riscv-collab/riscv-gnu-toolchain).
  
  _Can be omitted if you only want to run Chessy without compiling new programs._

- **Xilinx Vivado**: _Required to flash the ZCU102 board_   
  Place the build outputs in the following locations:
  - Bitstream: `./hw/build/cheshire.bit`
  - Debug Netlist (LTX): `./hw/build/cheshire.ltx`

  _Can be omitted if the board is already flashed with the Cheshire bitstream._

- **libjim**: _Required for building OpenOCD_   
  Install the library by running:
  ```bash
  sudo apt install libjim-dev
  ```

### 1. Clone the Repository and Set Up the Environment

Make sure to clone recursively to include all submodules:

```bash
git clone --recursive https://github.com/eml-eda/chessy.git
```

If you want to use custom paths instead of the defaults, you can set them in the `local.mk` file. For example, to use your own version of Messy, add or edit the following line in `local.mk`:

```make
MESSY_ROOT ?= /path/to/your/messy
```

After cloning the repository, build the necessary components by running:

```bash
make build-all
```

This will build the Cheshire tests, the Messy docker image, and OpenOCD with the required configurations.

### 2. Connect the ZCU102 Board and flash the Cheshire Bitstream
Connect the ZCU102 board to your host computer via USB, attach the UART adapter, and ensure the board is powered on. Then, flash the Cheshire bitstream using the following command:

```bash
make board-flash
```

Now, the board should be ready to run Cheshire workloads.

### 3. Run a test on Cheshire

To test that everything is set up correctly, you can run a simple helloworld program on Cheshire:

```bash
make run-all
```
This command will execute the Cheshire `helloworld` test, which is a basic program that prints "Hello World!" to the console through the UART adapter script. 


## Check Other Available Targets

You can check the rest of the targets in the `Makefile` by running:

```bash
make help
```

This will display all available targets and their descriptions, helping you understand what you can do with the Chessy framework.