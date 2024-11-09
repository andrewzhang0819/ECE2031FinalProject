-- MemoryBank.VHD
--
-- This SCOMP peripheral provides one 16-bit word of external memory for SCOMP.
-- Any value written to this peripheral can be read back.

LIBRARY IEEE;
LIBRARY altera_mf;
LIBRARY LPM;

USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE altera_mf.altera_mf_components.all;
USE LPM.LPM_COMPONENTS.ALL;

entity MemoryBank is
    port (
        clk           : in std_logic;      -- Clock signal
        rstn          : in std_logic;      -- Reset signal
        io_address    : in std_logic_vector(7 downto 0); -- I/O Address (0x70 to 0x7F)
        io_data_in    : in std_logic_vector(15 downto 0); -- Data from the processor -- I think that we should use one "inout" io_data vector like in the example
        io_data_out   : out std_logic_vector(15 downto 0); -- Data to the processor
        io_write      : in std_logic;      -- Write enable signal
        io_read       : in std_logic;      -- Read enable signal
        io_ready      : out std_logic      -- Ready signal for the processor
    );
end MemoryBank;

architecture Behavioral of MemoryBank is

    -- Define the memory size (2048 words, 16 bits per word)
    constant MEMORY_SIZE : integer := 2048;
    
    -- Declare the altsynram component
    signal mem_data_in  : std_logic_vector(15 downto 0);
    signal mem_data_out : std_logic_vector(15 downto 0);
    signal mem_address  : std_logic_vector(10 downto 0);
    signal mem_wren     : std_logic; -- Write enable for the RAM
    signal mem_rden     : std_logic; -- Read enable for the RAM

    -- Registers for control and status
    signal control_reg     : std_logic_vector(15 downto 0) := (others => '0'); -- Control register (0x70)
    signal status_reg      : std_logic_vector(15 downto 0) := (others => '0'); -- Status register (0x71)
    signal current_address : std_logic_vector(10 downto 0) := (others => '0'); -- Memory address register
    signal auto_increment  : std_logic := '0'; -- Auto increment feature
    signal write_protect   : std_logic := '0'; -- Write protection flag
    signal data_out_reg    : std_logic_vector(15 downto 0) := (others => '0'); -- Output data register

begin

    -- Instantiate the altsynram component
	altsyncram_component : altsyncram
        generic map (
            numwords_a => 8192, -- 4 banks x 2048 words per bank
            widthad_a => 13, -- 4 banks
            width_a => 16,
            init_file => "none", -- Change accordingly
            clock_enable_input_a => "BYPASS",
            clock_enable_output_a => "BYPASS",
            intended_device_family => "CYCLONE V",
            lpm_hint => "ENABLE_RUNTIME_MOD=NO",
            lpm_type => "altsyncram",
            operation_mode => "SINGLE_PORT",
            outdata_aclr_a => "NONE",
            outdata_reg_a => "UNREGISTERED",
            power_up_uninitialized => "FALSE",
            read_during_write_mode_port_a => "NEW_DATA_NO_NBE_READ",
            width_byteena_a => 1
        )
        port map (
            data_a       => mem_data_in,    -- Data to write to the memory
            q_a          => mem_data_out,   -- Data read from the memory
            address_a    => mem_address,    -- Address for the memory operation
            wren_a       => mem_wren,       -- Write enable signal
            rden_a       => mem_rden,       -- Read enable signal
            clock0        => clk             -- Clock signal
        );

    -- Memory read/write operations based on I/O address and control logic
    process(clk)
    begin
        if rising_edge(clk) then
            if rstn = '0' then
                -- Reset all registers
                control_reg <= (others => '0');
                status_reg <= (others => '0');
                current_address <= (others => '0');
                auto_increment <= '0';
                write_protect <= '0';
                io_ready <= '0';
            else
                -- Default ready signal
                io_ready <= '0';

                -- Decode I/O addresses
                case io_address is

                    -- Control Register (0x70)
                    when "01110000" => 
                        if io_write = '1' then
                            control_reg <= io_data_in; -- Write to control register
                            auto_increment <= io_data_in(0); -- Assume LSB is auto-increment flag
                            write_protect <= io_data_in(1); -- Assume bit 1 is write protection
                        elsif io_read = '1' then
                            io_data_out <= control_reg; -- Read from control register
                        end if;

                    -- Status Register (0x71)
                    when "01110001" =>
                        if io_read = '1' then
                            io_data_out <= status_reg; -- Read from status register
                        end if;

                    -- Data registers (0x72 to 0x7F for memory read/write)
                    when others =>
                        if io_address >= "01110010" and io_address <= "01111111" then
                            -- Writing to memory
                            if io_write = '1' then
                                if write_protect = '0' then
                                    -- Set the memory address and data for write operation
                                    mem_address <= current_address;
                                    mem_data_in <= io_data_in;
                                    mem_wren <= '1';  -- Enable write operation
                                    io_ready <= '1';
                                    -- Auto increment address
                                    if auto_increment = '1' then
                                        current_address <= current_address + 1;
                                    end if;
                                end if;
                            -- Reading from memory
                            elsif io_read = '1' then
                                -- Set the memory address for read operation
                                mem_address <= current_address;
                                mem_rden <= '1';  -- Enable read operation
                                data_out_reg <= mem_data_out;
                                io_data_out <= data_out_reg;
                                io_ready <= '1';
                                -- Auto increment address
                                if auto_increment = '1' then
                                    current_address <= current_address + 1;
                                end if;
                            end if;
                        end if;
                end case;

            end if;
        end if;
    end process;

end Behavioral;
