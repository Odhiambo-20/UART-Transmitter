-- uart_tx.vhd
-- UART Transmitter module in VHDL

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx is
    generic (
        CLK_FREQ    : integer := 50000000;  -- System clock frequency in Hz
        BAUD_RATE   : integer := 115200;    -- Desired baud rate
        DATA_BITS   : integer := 8;         -- Number of data bits
        STOP_BITS   : integer := 1          -- Number of stop bits
    );
    port (
        clk         : in  std_logic;         -- System clock
        reset       : in  std_logic;         -- Active high reset
        tx_data     : in  std_logic_vector(DATA_BITS-1 downto 0); -- Data to transmit
        tx_start    : in  std_logic;         -- Start transmission
        tx          : out std_logic;         -- Serial output
        tx_busy     : out std_logic          -- Transmitter busy indicator
    );
end entity uart_tx;

architecture rtl of uart_tx is
    -- Calculate the number of clock cycles per bit
    constant BIT_PERIOD : integer := CLK_FREQ / BAUD_RATE;
    
    -- UART transmitter states
    type tx_state_type is (IDLE, START_BIT, DATA_BITS_TX, STOP_BIT);
    signal state : tx_state_type := IDLE;
    
    -- Internal signals
    signal bit_counter   : integer range 0 to DATA_BITS-1 := 0;
    signal bit_timer     : integer range 0 to BIT_PERIOD-1 := 0;
    signal tx_data_reg   : std_logic_vector(DATA_BITS-1 downto 0);
    signal stop_bit_counter : integer range 0 to STOP_BITS := 0;
    
begin
    -- UART transmitter process
    tx_process: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                -- Reset state
                state <= IDLE;
                tx <= '1';  -- Idle state is high
                tx_busy <= '0';
                bit_counter <= 0;
                bit_timer <= 0;
                stop_bit_counter <= 0;
            else
                case state is
                    when IDLE =>
                        tx <= '1';  -- Idle state is high
                        tx_busy <= '0';
                        bit_counter <= 0;
                        bit_timer <= 0;
                        stop_bit_counter <= 0;
                        
                        -- Start transmission when tx_start is asserted
                        if tx_start = '1' then
                            tx_data_reg <= tx_data;  -- Latch data
                            state <= START_BIT;
                            tx_busy <= '1';
                        end if;
                        
                    when START_BIT =>
                        tx <= '0';  -- Start bit is low
                        
                        -- Wait for one bit period
                        if bit_timer < BIT_PERIOD-1 then
                            bit_timer <= bit_timer + 1;
                        else
                            bit_timer <= 0;
                            state <= DATA_BITS_TX;
                        end if;
                        
                    when DATA_BITS_TX =>
                        -- Output current data bit
                        tx <= tx_data_reg(bit_counter);
                        
                        -- Wait for one bit period
                        if bit_timer < BIT_PERIOD-1 then
                            bit_timer <= bit_timer + 1;
                        else
                            bit_timer <= 0;
                            
                            -- Move to next bit or stop bit
                            if bit_counter < DATA_BITS-1 then
                                bit_counter <= bit_counter + 1;
                            else
                                bit_counter <= 0;
                                state <= STOP_BIT;
                            end if;
                        end if;
                        
                    when STOP_BIT =>
                        tx <= '1';  -- Stop bit is high
                        
                        -- Wait for one bit period
                        if bit_timer < BIT_PERIOD-1 then
                            bit_timer <= bit_timer + 1;
                        else
                            bit_timer <= 0;
                            
                            -- Check if all stop bits are sent
                            if stop_bit_counter < STOP_BITS-1 then
                                stop_bit_counter <= stop_bit_counter + 1;
                            else
                                state <= IDLE;
                            end if;
                        end if;
                        
                end case;
            end if;
        end if;
    end process tx_process;
    
end architecture rtl;

-- Testbench for UART Transmitter
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx_tb is
end entity uart_tx_tb;

architecture tb of uart_tx_tb is
    -- Constants for simulation
    constant CLK_PERIOD : time := 20 ns;  -- 50MHz clock
    
    -- Component declaration
    component uart_tx is
        generic (
            CLK_FREQ    : integer := 50000000;
            BAUD_RATE   : integer := 115200;
            DATA_BITS   : integer := 8;
            STOP_BITS   : integer := 1
        );
        port (
            clk         : in  std_logic;
            reset       : in  std_logic;
            tx_data     : in  std_logic_vector(7 downto 0);
            tx_start    : in  std_logic;
            tx          : out std_logic;
            tx_busy     : out std_logic
        );
    end component;
    
    -- Signal declarations
    signal clk      : std_logic := '0';
    signal reset    : std_logic := '0';
    signal tx_data  : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_start : std_logic := '0';
    signal tx       : std_logic;
    signal tx_busy  : std_logic;
    
    -- For faster simulation
    constant SIM_BAUD_RATE : integer := 1000000;  -- 1Mbps for simulation
    
begin
    -- Clock generation
    clk <= not clk after CLK_PERIOD/2;
    
    -- Instantiate the Unit Under Test (UUT)
    uut: uart_tx
        generic map (
            CLK_FREQ  => 50000000,
            BAUD_RATE => SIM_BAUD_RATE,
            DATA_BITS => 8,
            STOP_BITS => 1
        )
        port map (
            clk       => clk,
            reset     => reset,
            tx_data   => tx_data,
            tx_start  => tx_start,
            tx        => tx,
            tx_busy   => tx_busy
        );
    
    -- Stimulus process
    stim_proc: process
    begin
        -- Reset
        reset <= '1';
        wait for 100 ns;
        reset <= '0';
        wait for 100 ns;
        
        -- Transmit byte 0x55 (01010101)
        tx_data  <= "01010101";
        tx_start <= '1';
        wait for CLK_PERIOD;
        tx_start <= '0';
        
        -- Wait for transmission to complete
        wait until tx_busy = '0';
        wait for 1 us;
        
        -- Transmit byte 0xAA (10101010)
        tx_data  <= "10101010";
        tx_start <= '1';
        wait for CLK_PERIOD;
        tx_start <= '0';
        
        -- Wait for transmission to complete
        wait until tx_busy = '0';
        wait for 1 us;
        
        -- End simulation
        wait for 10 us;
        assert false report "Simulation completed" severity failure;
    end process stim_proc;
    
end architecture tb;