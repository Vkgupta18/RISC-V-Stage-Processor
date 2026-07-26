# 5-Stage Pipelined RISC-V Processor — Build System
# Requires: Icarus Verilog (iverilog) and VVP

# Default target
all: simulate

# Compile
compile:
	iverilog -o PIPE_Processor_tb.exe PIPE_Processor_tb.v

# Simulate (compile + run)
simulate: compile
	vvp PIPE_Processor_tb.exe

# View waveform (requires GTKWave)
wave: simulate
	gtkwave pipe_output_wave.vcd &

# Clean build artifacts
clean:
	rm -f *.exe *.vcd *.vvp *.out

.PHONY: all compile simulate wave clean
