-- ExternalMemory.VHD
-- 2024.10.22
--
-- This SCOMP peripheral provides one 16-bit word of external memory for SCOMP.
-- Any value written to this peripheral can be read back.

library ieee;
library altera_mf;
library lpm;

use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use altera_mf.altera_mf_components.all;
use lpm.lpm_components.all;

ENTITY ExternalMemory IS
	PORT(
		clock     				: in    	STD_LOGIC;
		resetn					: in		STD_LOGIC;
		cs_data 					: in		STD_LOGIC;
		cs_bank					: in		STD_LOGIC;
		cs_address				: in		STD_LOGIC;
		io_data					: inout	STD_LOGIC_VECTOR(15 DOWNTO 0);
		io_write					: in    	STD_LOGIC;
		address_dbg				: out		STD_LOGIC_VECTOR(15 DOWNTO 0);
		address_a_dbg			: out		STD_LOGIC_VECTOR(17 DOWNTO 0);
		bank_dbg					: out		STD_LOGIC_VECTOR(1 DOWNTO 0);
		iodata_dbg				: out		STD_LOGIC_VECTOR(15 DOWNTO 0);
		csdata_dbg				: out		STD_LOGIC;
		csbank_dbg				: out		STD_LOGIC;
		csaddr_dbg				: out		STD_LOGIC;
		data_write_dbg			: out		STD_LOGIC_VECTOR(15 DOWNTO 0);
		data_read_dbg			: out		STD_LOGIC_VECTOR(15 DOWNTO 0);
		drive_out_dbg			: out 	STD_LOGIC
    );
END ExternalMemory;

ARCHITECTURE a OF ExternalMemory IS
	TYPE STATE_TYPE IS (
		idle,
		set_address, set_bank, data_reading, data_writing
	);

	SIGNAL bank				: STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL address			: sTD_LOGIC_VECTOR(15 DOWNTO 0);
	
	SIGNAL write_enable	: STD_LOGIC;
	SIGNAL address_a		: sTD_LOGIC_VECTOR(17 DOWNTO 0);
	SIGNAL data_write		: STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL data_read		: STD_LOGIC_VECTOR(15 DOWNTO 0);

	SIGNAL drive_out		: STD_LOGIC;
	
	SIGNAL state 			: STATE_TYPE;
	
	BEGIN
	
	altsyncram_component : altsyncram
	GENERIC MAP (
		numwords_a => 262144,
		widthad_a => 18,
		width_a => 16,
		init_file => "none",
		clock_enable_input_a => "BYPASS",
		clock_enable_output_a => "BYPASS",
		intended_device_family => "MAX 10",
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
		wren_a    => write_enable,
		clock0    => clock,	--use the 12Mhz clk
		address_a => address_a,
		data_a    => data_write,	
		q_a       => data_read
	);

	 -- Use Intel LPM IP to create tristate drivers
	IO_BUS: lpm_bustri
		GENERIC MAP (
		lpm_width => 16
	)
	PORT MAP (
		enabledt => drive_out, -- when SCOMP reads
		data     => data_read,  -- provide this value
		tridata  => io_data -- driving the IO_DATA bus
	);

	PROCESS(clock, resetn)
	BEGIN
		if resetn = '0' then
			state <= idle;
			--data_write <= "0000000000000000";
			address <= "0000000000000000";
			bank <= "00";
		elsif rising_edge(clock) then
			case state is
				when	idle =>
					if cs_address = '1' and io_write = '1' then
						state <= set_address;
					elsif cs_bank = '1' and io_write = '1' then
						state <= set_bank;
					elsif cs_data = '1' and io_write = '1' then
						state <= data_writing;
					elsif cs_data = '1' and io_write = '0' then
						state <= data_reading;
					else
						state <= idle;
					end if;
				when	set_address 	=>
					address <= io_data;
					state <= idle;
				when	set_bank 		=>
					bank <= io_data(1 downto 0);
					state <= idle;
				when	data_reading	=>
					if cs_data = '1' and io_write = '0' then		-- remain here long enough for scomp to read
						state <= data_reading;
					else
						state <= idle;
					end if;
				when	data_writing	=>
					data_write <= io_data;
					state <= idle;
				when others				=>
					state <= idle;
			end case;
		end if;
	END PROCESS;
	
	with state select write_enable <=
		'0' when idle,
		'0' when set_address,
		'0' when set_bank,
		'0' when data_reading,
		'1' when data_writing;

	with state select drive_out <=
		'0' when idle,
		'0' when set_address,
		'0' when set_bank,
		'1' when data_reading,
		'0' when data_writing;
		
	--with state select address <=
	--	address when idle,
	--	data_in when set_address,
	--	address when set_bank,
	--	address when data_read,
	--	address when data_write;
		
	--with state select bank <=
	--	bank 						when idle,
	--	bank 						when set_address,
	--	data_in(7 downto 0) 	when set_bank,
	--	bank 						when data_read,
	--	bank 						when data_write;
		
	-- data <= data_a;
	address_a <= bank & address;
	
	-- debug statements
	address_dbg 	<= address;
	address_a_dbg 	<= address_a;
	bank_dbg			<= bank;
	iodata_dbg		<= io_data;
	csdata_dbg		<= cs_data;
	csbank_dbg		<= cs_bank;
	csaddr_dbg		<= cs_address;
	data_write_dbg	<= data_write;
	data_read_dbg	<= data_read;
	drive_out_dbg	<= drive_out;
		
END a;