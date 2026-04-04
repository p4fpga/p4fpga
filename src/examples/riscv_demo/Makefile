# Makefile for RISC-V Action Processor Demo

P4C = p4c-p4fpga
P4_OPTIONS = --p4RuntimeFile sample.p4info.txt --p4RuntimeAlias sample

# Output directory for generated files
TARGET_DIR = $(shell pwd)/generated

all: compile

# Compile the P4 program to generate Bluespec files
compile: sample.p4
	@mkdir -p $(TARGET_DIR)
	$(P4C) $(P4_OPTIONS) -o $(TARGET_DIR) sample.p4

# Generate bitstream (when connected to actual hardware)
build: compile
	@echo "Building bitstream (not implemented in this demo)"

# Clean generated files
clean:
	rm -rf $(TARGET_DIR)

.PHONY: all compile build clean