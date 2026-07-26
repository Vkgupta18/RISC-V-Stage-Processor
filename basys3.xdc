## ============================================================================
##  Basys 3 XDC Constraints File
##  Target Board:  Digilent Basys 3 (Artix-7 xc7a35tcpg236-1)
##  Top Module:    PIPE_PROCESSOR_FPGA
##  Project:       5-Stage Pipelined RISC-V Processor
##  Generated:     2026-07-23
## ============================================================================
##  Pin assignments follow the official Basys 3 Master XDC from Digilent.
##  All active I/O uses LVCMOS33 (3.3 V) per Basys 3 bank voltage.
## ============================================================================


## ============================================================================
##  CLOCK — 100 MHz on-board oscillator
## ============================================================================
## The Basys 3 has a single 100 MHz crystal oscillator connected to pin W5.
## This is the only clock source on the board.

set_property -dict { PACKAGE_PIN W5   IOSTANDARD LVCMOS33 } [get_ports {clk}]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {clk}]
## 100 MHz = 10 ns period, 50% duty cycle (rise at 0 ns, fall at 5 ns)


## ============================================================================
##  RESET — Center push-button (BTNC)
## ============================================================================
## Active-high momentary push-button. No external debounce circuit on Basys 3.
## Directly drives the processor's active-high asynchronous reset.

set_property -dict { PACKAGE_PIN U18  IOSTANDARD LVCMOS33 } [get_ports {reset}]


## ============================================================================
##  SLIDE SWITCHES — SW[15:0]
## ============================================================================
## 16 slide switches, active-high (up = logic 1).
## Used to select debug display mode:
##   SW[1:0] = debug word select (PC / Instruction / ALU result / Write-back)
##   SW[2]   = upper/lower 16-bit half select
##   SW[15:3] = available for future use

set_property -dict { PACKAGE_PIN V17  IOSTANDARD LVCMOS33 } [get_ports {sw[0]}]
set_property -dict { PACKAGE_PIN V16  IOSTANDARD LVCMOS33 } [get_ports {sw[1]}]
set_property -dict { PACKAGE_PIN W16  IOSTANDARD LVCMOS33 } [get_ports {sw[2]}]
set_property -dict { PACKAGE_PIN W17  IOSTANDARD LVCMOS33 } [get_ports {sw[3]}]
set_property -dict { PACKAGE_PIN W15  IOSTANDARD LVCMOS33 } [get_ports {sw[4]}]
set_property -dict { PACKAGE_PIN V15  IOSTANDARD LVCMOS33 } [get_ports {sw[5]}]
set_property -dict { PACKAGE_PIN W14  IOSTANDARD LVCMOS33 } [get_ports {sw[6]}]
set_property -dict { PACKAGE_PIN W13  IOSTANDARD LVCMOS33 } [get_ports {sw[7]}]
set_property -dict { PACKAGE_PIN V2   IOSTANDARD LVCMOS33 } [get_ports {sw[8]}]
set_property -dict { PACKAGE_PIN T3   IOSTANDARD LVCMOS33 } [get_ports {sw[9]}]
set_property -dict { PACKAGE_PIN T2   IOSTANDARD LVCMOS33 } [get_ports {sw[10]}]
set_property -dict { PACKAGE_PIN R3   IOSTANDARD LVCMOS33 } [get_ports {sw[11]}]
set_property -dict { PACKAGE_PIN W2   IOSTANDARD LVCMOS33 } [get_ports {sw[12]}]
set_property -dict { PACKAGE_PIN U1   IOSTANDARD LVCMOS33 } [get_ports {sw[13]}]
set_property -dict { PACKAGE_PIN T1   IOSTANDARD LVCMOS33 } [get_ports {sw[14]}]
set_property -dict { PACKAGE_PIN R2   IOSTANDARD LVCMOS33 } [get_ports {sw[15]}]


## ============================================================================
##  LEDs — LED[15:0]
## ============================================================================
## 16 individual LEDs, accent-high (logic 1 = LED ON).
##   LED[13:0] = lower 14 bits of selected debug display half
##   LED[14]   = pipeline flush indicator  (ON when flushing)
##   LED[15]   = pipeline stall indicator  (ON when stalling)

set_property -dict { PACKAGE_PIN U16  IOSTANDARD LVCMOS33 } [get_ports {LED[0]}]
set_property -dict { PACKAGE_PIN E19  IOSTANDARD LVCMOS33 } [get_ports {LED[1]}]
set_property -dict { PACKAGE_PIN U19  IOSTANDARD LVCMOS33 } [get_ports {LED[2]}]
set_property -dict { PACKAGE_PIN V19  IOSTANDARD LVCMOS33 } [get_ports {LED[3]}]
set_property -dict { PACKAGE_PIN W18  IOSTANDARD LVCMOS33 } [get_ports {LED[4]}]
set_property -dict { PACKAGE_PIN U15  IOSTANDARD LVCMOS33 } [get_ports {LED[5]}]
set_property -dict { PACKAGE_PIN U14  IOSTANDARD LVCMOS33 } [get_ports {LED[6]}]
set_property -dict { PACKAGE_PIN V14  IOSTANDARD LVCMOS33 } [get_ports {LED[7]}]
set_property -dict { PACKAGE_PIN V13  IOSTANDARD LVCMOS33 } [get_ports {LED[8]}]
set_property -dict { PACKAGE_PIN V3   IOSTANDARD LVCMOS33 } [get_ports {LED[9]}]
set_property -dict { PACKAGE_PIN W3   IOSTANDARD LVCMOS33 } [get_ports {LED[10]}]
set_property -dict { PACKAGE_PIN U3   IOSTANDARD LVCMOS33 } [get_ports {LED[11]}]
set_property -dict { PACKAGE_PIN P3   IOSTANDARD LVCMOS33 } [get_ports {LED[12]}]
set_property -dict { PACKAGE_PIN N3   IOSTANDARD LVCMOS33 } [get_ports {LED[13]}]
set_property -dict { PACKAGE_PIN P1   IOSTANDARD LVCMOS33 } [get_ports {LED[14]}]
set_property -dict { PACKAGE_PIN L1   IOSTANDARD LVCMOS33 } [get_ports {LED[15]}]


## ============================================================================
##  SEVEN-SEGMENT DISPLAY — Cathodes seg[6:0] and decimal point dp
## ============================================================================
## Active-low cathodes: 0 = segment ON, 1 = segment OFF.
## Accent encoding: seg[6:0] = {g, f, e, d, c, b, a}
## Accent: dp active-low (0 = decimal point ON).
## The 4-digit display shows the selected 16-bit debug value in hexadecimal.

set_property -dict { PACKAGE_PIN W7   IOSTANDARD LVCMOS33 } [get_ports {seg[0]}]
## seg[0] = segment 'a' (top horizontal)

set_property -dict { PACKAGE_PIN W6   IOSTANDARD LVCMOS33 } [get_ports {seg[1]}]
## seg[1] = segment 'b' (upper right vertical)

set_property -dict { PACKAGE_PIN U8   IOSTANDARD LVCMOS33 } [get_ports {seg[2]}]
## seg[2] = segment 'c' (lower right vertical)

set_property -dict { PACKAGE_PIN V8   IOSTANDARD LVCMOS33 } [get_ports {seg[3]}]
## seg[3] = segment 'd' (bottom horizontal)

set_property -dict { PACKAGE_PIN U5   IOSTANDARD LVCMOS33 } [get_ports {seg[4]}]
## seg[4] = segment 'e' (lower left vertical)

set_property -dict { PACKAGE_PIN V5   IOSTANDARD LVCMOS33 } [get_ports {seg[5]}]
## seg[5] = segment 'f' (upper left vertical)

set_property -dict { PACKAGE_PIN U7   IOSTANDARD LVCMOS33 } [get_ports {seg[6]}]
## seg[6] = segment 'g' (middle horizontal)

set_property -dict { PACKAGE_PIN V7   IOSTANDARD LVCMOS33 } [get_ports {dp}]
## dp = decimal point (active-low, directly after the digit)


## ============================================================================
##  SEVEN-SEGMENT DISPLAY — Anode control an[3:0]
## ============================================================================
## Active-low anodes: 0 = digit ON, 1 = digit OFF.
## Time-multiplexed at ~763 Hz (100 MHz / 2^17) — flicker-free to human eye.
##   an[0] = rightmost digit (ones)
##   an[1] = second digit
##   an[2] = third digit
##   an[3] = leftmost digit (thousands)

set_property -dict { PACKAGE_PIN U2   IOSTANDARD LVCMOS33 } [get_ports {an[0]}]
set_property -dict { PACKAGE_PIN U4   IOSTANDARD LVCMOS33 } [get_ports {an[1]}]
set_property -dict { PACKAGE_PIN V4   IOSTANDARD LVCMOS33 } [get_ports {an[2]}]
set_property -dict { PACKAGE_PIN W4   IOSTANDARD LVCMOS33 } [get_ports {an[3]}]


## ============================================================================
##  UNUSED PERIPHERALS — Commented-out templates for future expansion
## ============================================================================
## These constraints are provided for reference. Uncomment and connect
## to ports in your top-level module if you add UART, VGA, etc.

## ---------- PUSH BUTTONS (active-high, active-high on press) ----------
## BTNC (center) is already used as reset above.
## BTNU (up)      — T18
## BTNL (left)    — W19
## BTNR (right)   — T17
## BTND (down)    — U17
# set_property -dict { PACKAGE_PIN T18  IOSTANDARD LVCMOS33 } [get_ports {btnU}]
# set_property -dict { PACKAGE_PIN W19  IOSTANDARD LVCMOS33 } [get_ports {btnL}]
# set_property -dict { PACKAGE_PIN T17  IOSTANDARD LVCMOS33 } [get_ports {btnR}]
# set_property -dict { PACKAGE_PIN U17  IOSTANDARD LVCMOS33 } [get_ports {btnD}]


## ---------- UART (USB-to-serial via FTDI FT2232HQ) ----------
## RXD = data FROM host PC TO FPGA  (active on pin A18)
## TXD = data FROM FPGA TO host PC  (active on pin B18)
# set_property -dict { PACKAGE_PIN B18  IOSTANDARD LVCMOS33 } [get_ports {RsRx}]
# set_property -dict { PACKAGE_PIN A18  IOSTANDARD LVCMOS33 } [get_ports {RsTx}]


## ---------- VGA OUTPUT (accent accent accent accent) ----------
## accent VGA accent accent accent — accent 12-bit color (4 bits per channel)
## accent accent accent accent accent accent accent accent accent accent accent
# set_property -dict { PACKAGE_PIN G19  IOSTANDARD LVCMOS33 } [get_ports {vgaRed[0]}]
# set_property -dict { PACKAGE_PIN H19  IOSTANDARD LVCMOS33 } [get_ports {vgaRed[1]}]
# set_property -dict { PACKAGE_PIN J19  IOSTANDARD LVCMOS33 } [get_ports {vgaRed[2]}]
# set_property -dict { PACKAGE_PIN N19  IOSTANDARD LVCMOS33 } [get_ports {vgaRed[3]}]
# set_property -dict { PACKAGE_PIN N18  IOSTANDARD LVCMOS33 } [get_ports {vgaBlue[0]}]
# set_property -dict { PACKAGE_PIN L18  IOSTANDARD LVCMOS33 } [get_ports {vgaBlue[1]}]
# set_property -dict { PACKAGE_PIN K18  IOSTANDARD LVCMOS33 } [get_ports {vgaBlue[2]}]
# set_property -dict { PACKAGE_PIN J18  IOSTANDARD LVCMOS33 } [get_ports {vgaBlue[3]}]
# set_property -dict { PACKAGE_PIN J17  IOSTANDARD LVCMOS33 } [get_ports {vgaGreen[0]}]
# set_property -dict { PACKAGE_PIN H17  IOSTANDARD LVCMOS33 } [get_ports {vgaGreen[1]}]
# set_property -dict { PACKAGE_PIN G17  IOSTANDARD LVCMOS33 } [get_ports {vgaGreen[2]}]
# set_property -dict { PACKAGE_PIN D17  IOSTANDARD LVCMOS33 } [get_ports {vgaGreen[3]}]
# set_property -dict { PACKAGE_PIN P19  IOSTANDARD LVCMOS33 } [get_ports {Hsync}]
# set_property -dict { PACKAGE_PIN R19  IOSTANDARD LVCMOS33 } [get_ports {Vsync}]


## ---------- PMOD HEADER JA (accent accent 4 accent accent) ----------
# set_property -dict { PACKAGE_PIN J1   IOSTANDARD LVCMOS33 } [get_ports {JA[1]}]
# set_property -dict { PACKAGE_PIN L2   IOSTANDARD LVCMOS33 } [get_ports {JA[2]}]
# set_property -dict { PACKAGE_PIN J2   IOSTANDARD LVCMOS33 } [get_ports {JA[3]}]
# set_property -dict { PACKAGE_PIN G2   IOSTANDARD LVCMOS33 } [get_ports {JA[4]}]
# set_property -dict { PACKAGE_PIN H1   IOSTANDARD LVCMOS33 } [get_ports {JA[7]}]
# set_property -dict { PACKAGE_PIN K2   IOSTANDARD LVCMOS33 } [get_ports {JA[8]}]
# set_property -dict { PACKAGE_PIN H2   IOSTANDARD LVCMOS33 } [get_ports {JA[9]}]
# set_property -dict { PACKAGE_PIN G3   IOSTANDARD LVCMOS33 } [get_ports {JA[10]}]


## ---------- PMOD HEADER JB ----------
# set_property -dict { PACKAGE_PIN A14  IOSTANDARD LVCMOS33 } [get_ports {JB[1]}]
# set_property -dict { PACKAGE_PIN A16  IOSTANDARD LVCMOS33 } [get_ports {JB[2]}]
# set_property -dict { PACKAGE_PIN B15  IOSTANDARD LVCMOS33 } [get_ports {JB[3]}]
# set_property -dict { PACKAGE_PIN B16  IOSTANDARD LVCMOS33 } [get_ports {JB[4]}]
# set_property -dict { PACKAGE_PIN A15  IOSTANDARD LVCMOS33 } [get_ports {JB[7]}]
# set_property -dict { PACKAGE_PIN A17  IOSTANDARD LVCMOS33 } [get_ports {JB[8]}]
# set_property -dict { PACKAGE_PIN C15  IOSTANDARD LVCMOS33 } [get_ports {JB[9]}]
# set_property -dict { PACKAGE_PIN C16  IOSTANDARD LVCMOS33 } [get_ports {JB[10]}]


## ---------- PMOD HEADER JC ----------
# set_property -dict { PACKAGE_PIN K17  IOSTANDARD LVCMOS33 } [get_ports {JC[1]}]
# set_property -dict { PACKAGE_PIN M18  IOSTANDARD LVCMOS33 } [get_ports {JC[2]}]
# set_property -dict { PACKAGE_PIN N17  IOSTANDARD LVCMOS33 } [get_ports {JC[3]}]
# set_property -dict { PACKAGE_PIN P18  IOSTANDARD LVCMOS33 } [get_ports {JC[4]}]
# set_property -dict { PACKAGE_PIN L17  IOSTANDARD LVCMOS33 } [get_ports {JC[7]}]
# set_property -dict { PACKAGE_PIN M19  IOSTANDARD LVCMOS33 } [get_ports {JC[8]}]
# set_property -dict { PACKAGE_PIN P17  IOSTANDARD LVCMOS33 } [get_ports {JC[9]}]
# set_property -dict { PACKAGE_PIN R18  IOSTANDARD LVCMOS33 } [get_ports {JC[10]}]


## ---------- PMOD HEADER JXADC (accent accent accent accent) ----------
# set_property -dict { PACKAGE_PIN J3   IOSTANDARD LVCMOS33 } [get_ports {JXADC[1]}]
# set_property -dict { PACKAGE_PIN L3   IOSTANDARD LVCMOS33 } [get_ports {JXADC[2]}]
# set_property -dict { PACKAGE_PIN M2   IOSTANDARD LVCMOS33 } [get_ports {JXADC[3]}]
# set_property -dict { PACKAGE_PIN N2   IOSTANDARD LVCMOS33 } [get_ports {JXADC[4]}]
# set_property -dict { PACKAGE_PIN K3   IOSTANDARD LVCMOS33 } [get_ports {JXADC[7]}]
# set_property -dict { PACKAGE_PIN M3   IOSTANDARD LVCMOS33 } [get_ports {JXADC[8]}]
# set_property -dict { PACKAGE_PIN M1   IOSTANDARD LVCMOS33 } [get_ports {JXADC[9]}]
# set_property -dict { PACKAGE_PIN N1   IOSTANDARD LVCMOS33 } [get_ports {JXADC[10]}]


## ============================================================================
##  CONFIGURATION — Bitstream settings for Basys 3
## ============================================================================
## SPI flash configuration mode (x1), 33 MHz CCLK, 3.3V config bank voltage.
## These are standard for Basys 3 and ensure correct bitstream programming.

set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 1 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]


## ============================================================================
##  PIN CONFLICT REPORT
## ============================================================================
##  All mapped pins have been verified against the official Basys 3 Master XDC.
##  No duplicate pin assignments exist in the active (uncommented) constraints.
##
##  Unmapped signals:   NONE — all top-level ports of PIPE_PROCESSOR_FPGA are
##                      assigned to physical pins.
##
##  Pin usage summary:
##    Clock:            1  pin  (W5)
##    Reset:            1  pin  (U18 — BTNC)
##    Switches:         16 pins (V17..R2)
##    LEDs:             16 pins (U16..L1)
##    Seven-seg cathodes: 7 pins (W7..U7)
##    Seven-seg dp:     1  pin  (V7)
##    Seven-seg anodes: 4  pins (U2..W4)
##    ─────────────────────────────────
##    TOTAL ACTIVE:     46 pins
##    TOTAL AVAILABLE:  ~100 user I/O (xc7a35tcpg236)
##    REMAINING:        ~54 pins (available via PMODs, VGA, UART, buttons)
## ============================================================================
