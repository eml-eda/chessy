# ♟️ Chessy (Cheshire + Messy)

**Chessy** is a hardware-in-the-loop co-simulation framework that integrates the [Cheshire host platform](https://github.com/pulp-platform/cheshire), running on an FPGA, with the [Messy extra-functional simulator](https://github.com/eml-eda/messy), running on the host computer. This setup allows Messy to monitor and simulate extra-functional properties while Cheshire executes workloads in real hardware.

This repository contains the utilities to run Chessy, including the necessary scripts and configurations to set up the co-simulation environment.

## Quick Start

Clone the repository with all submodules:

```bash
git clone --recursive https://github.com/eml-eda/chessy.git
```