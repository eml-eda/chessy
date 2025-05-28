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

### 1. Clone the Repository

Make sure to clone recursively to include all submodules:

```bash
git clone --recursive https://github.com/eml-eda/chessy.git
```
