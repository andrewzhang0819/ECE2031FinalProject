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

ENTITY tempMemoryBank IS
    PORT(
        RESETN      : in STD_LOGIC;
        CS          : in STD_LOGIC;
        CLOCK       : in STD_LOGIC;
        IO_ADDRESS  : in STD_LOGIC_VECTOR(7 downto 0);
        IO_WRITE    : in STD_LOGIC;
        IO_READ     : in STD_LOGIC;
        IO_DATA     : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
END tempMemoryBank;

ARCHITECTURE a OF tempMemoryBank IS
    -- Memory size = 2048 words
    -- check!!
    type state_type is (
        ex_mb_write, -- MemoryBank write
        ex_mb_read, -- MemoryBank read
        idle, -- inital state
        fetch -- indicates processor is ready to begin fetching instructions or is the "status ready to go"
    )

    -- Signal for memory bank
    signal memory_bank_data : std_logic_vector(15 downto 0);
    signal memory_bank_addr : std_logic_vector(10 downto 0);
    signal memory_bank_write_enable : std_logic;

    BEGIN
    -- use altsyncram component for unified program and data memory
    altsyncram_component : altsyncram
    GENERIC MAP (
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
    PORT MAP (
        wren_a    => MW,
        clock0    => clock,
        address_a => next_mem_addr,
        data_a    => AC,
        q_a       => mem_data
    );

    PROCESS(CLOCK, RESETN)
    BEGIN
        if (RESETN = '0') then
            -- initalization code for the idle state
            state <= idle;
        elsif (rising_edge(CLOCK)) then
            case state is
                when idle =>
                -- initalization logic for the idle state
                    state <= fetch;
                when fetch => out  
                    PC <= PC + 1 -- increment PC to next 
                    IO_WRITE_int <= '0' -- lower IO_WRITE after aninstruction address 
                    -- Implement some way to get to ex_mb_write and ex_mb_read states
                    IF IO_WRITE = '1' THEN 
                        state <= ex_mb_write;
                    ElSIF IO_WRITE = '0' THEN 
                        state <= ex_mb_read;
                when ex_mb_write =>
                    memory_bank_write_enable <= '1';
                    memory_bank_addr <= IO_ADDR(10 downto 0);
                    state <= fetch;
                when ex_mb_read =>
                    memory_bank_write_enable <= '0';
                    AC <= memory_bank_data; -- Load data into AC from memory bank
                    state <= fetch;
                
                -- Proceeding
            end csae;
        end if;
    END PROCESS;
END a;