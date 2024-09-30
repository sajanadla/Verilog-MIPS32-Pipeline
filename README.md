# Verilog-MIPS32-Pipeline


This repository contains Verilog code for a pipelined MIPS32 processor. The MIPS32 architecture is a popular Reduced Instruction Set Computing (RISC) architecture widely used in embedded systems and educational settings. This project implements a 5-stage pipeline to enhance instruction throughput.

## Features

* **Pipelined Implementation:**  The processor employs a 5-stage pipeline (Instruction Fetch, Instruction Decode/Register Fetch, Execute, Memory Access, and Write Back) to improve performance.
* **MIPS32 Instruction Subset:** Supports a subset of MIPS32 instructions, including:
    * Load/Store instructions (LW, SW)
    * Arithmetic and Logic instructions (ADD, SUB, AND, OR, MUL, SLT, ADDI, SUBI, SLTI)
    * Branch instructions (BEQZ, BNEQZ)
    * Jump instruction (J)
    * Halt instruction (HLT)
* **32-bit Architecture:**  Operates on 32-bit data and addresses.
* **Register File:**  Includes 32 general-purpose registers (R0-R31), with R0 hardwired to zero.
* **Program Counter (PC):**  A dedicated register for tracking the address of the next instruction.

## Implementation Details

* **Verilog HDL:** The processor is implemented using Verilog hardware description language.
* **5-Stage Pipeline:**  Divides instruction execution into five stages to allow concurrent execution of multiple instructions.
* **Hazard Detection and Forwarding:**  Includes mechanisms to handle data hazards and control hazards that arise in a pipelined architecture.
* **Testbench:** Provides a testbench for verifying the functionality of the processor.


## Project Structure

* `src/`: Contains the Verilog source files for the processor components (e.g., datapath, control unit, register file, memory).
* `tb/`: Contains the testbench files for verifying the processor.
* `asm/`:  (Optional) May contain assembly code examples.

