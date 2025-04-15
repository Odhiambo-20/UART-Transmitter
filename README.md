# UART Transmitter Implementation in VHDL

## Overview
This repository contains a UART (Universal Asynchronous Receiver/Transmitter) transmitter module implemented in VHDL. The transmitter is configurable for various parameters including clock frequency, baud rate, data bits, and stop bits.

## Features
- Configurable system clock frequency
- Configurable baud rate
- Configurable number of data bits (default 8)
- Configurable number of stop bits (default 1)
- Active high reset
- Busy indicator output

## Files
- `uart_tx.vhd` - Main VHDL file containing:
  - `uart_tx` entity - The UART transmitter implementation
  - `uart_tx_tb` entity - Testbench for verification

## Port Description
- `clk` - System clock input
- `reset` - Active high reset input
- `tx_data` - Data to be transmitted (parallel input)
- `tx_start` - Start transmission signal (active high pulse)
- `tx` - Serial data output
- `tx_busy` - Indicates when transmitter is busy (active high)

## Generics
The module can be customized using the following generics:
- `CLK_FREQ` - System clock frequency in Hz (default: 50,000,000 Hz)
- `BAUD_RATE` - Desired baud rate (default: 115,200 bps)
- `DATA_BITS` - Number of data bits (default: 8)
- `STOP_BITS` - Number of stop bits (default: 1)

## Usage

### Instantiation
```vhdl
uart_instance : entity work.uart_tx
    generic map (
        CLK_FREQ  => 100000000,  -- 100 MHz
        BAUD_RATE => 9600,       -- 9600 bps
        DATA_BITS => 8,          -- 8 data bits
        STOP_BITS => 1           -- 1 stop bit
    )
    port map (
        clk       => system_clk,
        reset     => system_rst,
        tx_data   => data_to_send,
        tx_start  => start_send,
        tx        => uart_tx_pin,
        tx_busy   => tx_busy_flag
    );
```

### Timing Diagram
1. Set `tx_data` to the byte to be transmitted
2. Assert `tx_start` for one clock cycle
3. Wait for `tx_busy` to be deasserted before sending next byte

## Simulation
The transmitter includes a testbench that can be used to verify functionality:

```bash
# GHDL example
ghdl -a uart_tx.vhd
ghdl -e uart_tx_tb
ghdl -r uart_tx_tb --vcd=uart_tx.vcd

# ModelSim example
vsim -do "do simulate.do"
```

## Implementation Details
- The transmitter operates using a state machine with four states:
  - IDLE: Waiting for start signal
  - START_BIT: Sending start bit
  - DATA_BITS_TX: Sending data bits
  - STOP_BIT: Sending stop bit(s)
- The design calculates the bit period based on the system clock and baud rate.

## License
This UART transmitter implementation is provided under the MIT License.
