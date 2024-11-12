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
use ieee.numeric_std.all;
use altera_mf.altera_mf_components.all;
use lpm.lpm_components.all;

ENTITY ExternalMemory IS
	PORT(
		clock     				: in    	STD_LOGIC;
		resetn					: in		STD_LOGIC;
		cs_data 					: in		STD_LOGIC;
		cs_bank					: in		STD_LOGIC;
		cs_address				: in		STD_LOGIC;
		cs_autoinc				: in 		STD_LOGIC;
		cs_writeprot			: in		STD_LOGIC;
		io_data					: inout	STD_LOGIC_VECTOR(15 DOWNTO 0);
		io_write					: in    	STD_LOGIC;
		address_dbg				: out		STD_LOGIC_VECTOR(15 DOWNTO 0);
		address_a_dbg			: out		STD_LOGIC_VECTOR(17 DOWNTO 0);
		bank_dbg					: out		STD_LOGIC_VECTOR(1 DOWNTO 0);
		iodata_dbg				: out		STD_LOGIC_VECTOR(15 DOWNTO 0);
		csdata_dbg				: out		STD_LOGIC;
		csbank_dbg				: out		STD_LOGIC;
		csaddr_dbg				: out		STD_LOGIC;
		csincr_dbg				: out		STD_LOGIC;
		data_write_dbg			: out		STD_LOGIC_VECTOR(15 DOWNTO 0);
		data_read_dbg			: out		STD_LOGIC_VECTOR(15 DOWNTO 0);
		drive_out_dbg			: out 	STD_LOGIC;
		user_set_dbg			: out		STD_LOGIC;
		io_write_dbg			: out		STD_LOGIC;
		incren_dbg				: out		STD_LOGIC;
		lock_dbg					: out		STD_LOGIC_VECTOR(3 DOWNTO 0);
		writeen_dbg				: out		STD_LOGIC;
		csprot_dbg				: out		STD_LOGIC
    );
END ExternalMemory;

ARCHITECTURE a OF ExternalMemory IS
	TYPE STATE_TYPE IS (
		idle,
		set_address, set_bank, data_reading, data_writing, increment, set_incr, set_prot
	);

	SIGNAL bank				: STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL address			: sTD_LOGIC_VECTOR(15 DOWNTO 0);
	
	SIGNAL write_enable	: STD_LOGIC;
	SIGNAL address_a		: sTD_LOGIC_VECTOR(17 DOWNTO 0);
	SIGNAL data_write		: STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL data_read		: STD_LOGIC_VECTOR(15 DOWNTO 0);

	SIGNAL drive_out		: STD_LOGIC;
	
	SIGNAL user_set		: STD_LOGIC;
	
	SIGNAL inc_enable		: STD_LOGIC;
	
	SIGNAL locked_banks	: STD_LOGIC_VECTOR(3 DOWNTO 0);
	SIGNAL write_en		: STD_LOGIC;
	
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
			user_set <= '0';
			inc_enable <= '1';
			state <= idle;
			address <= "0000000000000000";
			bank <= "00";
		elsif rising_edge(clock) then
			case state is																-- state transition logic
				when	idle =>															-- idle
					if cs_autoinc = '1' then
						state <= set_incr;
					elsif cs_address = '1' and io_write = '1' then
						state <= set_address;
					elsif cs_bank = '1' and io_write = '1' then
						state <= set_bank;
					elsif cs_writeprot = '1' and io_write = '1' then
						state <= set_prot;
					elsif cs_data = '1' and io_write = '1' then
						state <= data_writing;
						if user_set = '0' and inc_enable = '1' then
							state <= increment;
						else
							state <= data_writing;
						end if;
					elsif cs_data = '1' and io_write = '0' then
						state <= data_reading;
						if user_set = '0' and inc_enable = '1' then
							state <= increment;
						else
							state <= data_reading;
						end if;
					else
						state <= idle;
					end if;
					
				when	increment		=>
					address <= address + 1;
					if cs_data = '1' and io_write = '1' then
						state <= data_writing;
					elsif cs_data = '1' and io_write = '0' then
						state <= data_reading;
					else
						state <= idle;
					end if;
				when	set_address 	=>
					user_set <= '1';
					address <= io_data;
					state <= idle;
				when	set_bank 		=>
					bank <= io_data(1 downto 0);
					
					state <= idle;
				when	set_prot =>
										
					case bank is 
						when "00" =>
							locked_banks(0) <= io_data(0);
						when "01" =>
							locked_banks(1) <= io_data(0);
						when "10" =>
							locked_banks(2) <= io_data(0);
						when "11" =>
							locked_banks(3) <= io_data(0);
						when others =>
							locked_banks(0) <= io_data(0);
					end case;
					
					state <= idle;
					
				when	data_reading	=>
					if cs_data = '1' and io_write = '0' then		-- remain here long enough for scomp to read
						state <= data_reading;
					else
						state <= idle;
					end if;
					user_set <= '0';
				when	data_writing	=>
					
--					case bank is 
--						when "00" =>
--							if locked_banks(0) = '1' then
--								write_en <= '0';
--							else
--								write_en <= '1';
--							end if;
--						when "01" =>
--							if locked_banks(1) = '1' then
--								write_en <= '0';
--							else
--								write_en <= '1';
--							end if;
--						when "10" =>
--							if locked_banks(2) = '1' then
--								write_en <= '0';
--							else
--								write_en <= '1';
--							end if;
--						when "11" =>
--							if locked_banks(3) = '1' then
--								write_en <= '0';
--							else
--								write_en <= '1';
--							end if;
--						when others =>
--							write_en <= '0';
--					end case;
				
					if cs_data = '1' and io_write = '1' and write_en =  '1' then		-- remain here so that the address is not immediately incremented
						data_write <= io_data;
					else
						state <= idle;
					end if;
					user_set <= '0';
				when	set_incr	=>
					if io_data = 0 and cs_autoinc = '1' then
						inc_enable <= '0';
					elsif io_data /= 0 and cs_autoinc = '1' then
						inc_enable <= '1';
					end if;
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
		'1' when data_writing,
		'0' when increment,
		'0' when set_incr,
		'0' when set_prot;
		
	with bank select write_en <=
		NOT(locked_banks(0)) when "00",
		NOT(locked_banks(1)) when "01",
		NOT(locked_banks(2)) when "10",
		NOT(locked_banks(3)) when "11";

	with state select drive_out <=
		'0' when idle,
		'0' when set_address,
		'0' when set_bank,
		'1' when data_reading,
		'0' when data_writing,
		'0' when increment,
		'0' when set_incr,
		'0' when set_prot;
		
	address_a <= bank & address;
	
	-- debug statements
	address_dbg 	<= address;
	address_a_dbg 	<= address_a;
	bank_dbg			<= bank;
	iodata_dbg		<= io_data;
	csdata_dbg		<= cs_data;
	csbank_dbg		<= cs_bank;
	csaddr_dbg		<= cs_address;
	csincr_dbg		<= cs_autoinc;
	data_write_dbg	<= data_write;
	data_read_dbg	<= data_read;
	drive_out_dbg	<= drive_out;
	user_set_dbg	<= user_set;
	io_write_dbg	<= io_write;
	incren_dbg		<= inc_enable;
	lock_dbg			<= locked_banks;
	writeen_dbg		<= write_en;
	csprot_dbg		<= cs_writeprot;
	
		
END a;