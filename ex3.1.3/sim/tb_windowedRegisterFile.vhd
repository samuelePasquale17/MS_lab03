library ieee; 
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;
use work.constants.all;


entity TB is 
end TB; 

architecture TEST of TB is

	constant N : integer := 8;
	constant M : integer := 3;
	constant F : integer := 8;
	constant WIDTH : integer := 8;
	
	-- component under test
	component windowedRegisterFile is
		generic(
			F : integer := F_WRF; -- number of windows in the register file
			N : integer := N_WRF; -- number of registers per window (globals excluded)
			M : integer := M_WRF;  -- numeber of global registers
			WIDTH : integer := WIDTHbit_WRF  -- number of bits per register
		);
		port (
			Clk : in std_logic;  -- clock signal
			Rst : in std_logic;  -- reset signal
			En : in std_logic;  -- enable signal
			RD1 : in std_logic;  -- control signal read 1
			RD2 : in std_logic;  -- control signal read 2
			WR : in std_logic;  -- control signal write

			-- from sub routines
			call_subroutine : in std_logic;  -- call signal from subroutine
			return_subroutine : in std_logic;  -- return signal from subroutine

			-- from main memory
			start_seq_MEM : in std_logic;  -- start sequence of registers
			ack_MEM : in std_logic;  -- end sequence of registers

			-- addresses
			Addr_WR : in std_logic_vector(integer(ceil(log2(real(3*N + M) + real(1))))-1 downto 0);    		-- address ports
			Addr_RD1 : in std_logic_vector(integer(ceil(log2(real(3*N + M) + real(1))))-1 downto 0);
			Addr_RD2 : in std_logic_vector(integer(ceil(log2(real(3*N + M) + real(1))))-1 downto 0);

			-- data
			DataIn : in std_logic_vector(WIDTH-1 downto 0);	 -- input port
			DataOut1 : out std_logic_vector(WIDTH-1 downto 0);  -- output port1
			DataOut2 : out std_logic_vector(WIDTH-1 downto 0);  -- output port2

			-- bus with main memory
			bus_MEM_in : in std_logic_vector(WIDTH-1 downto 0);  -- spill/fill on bus on port #2 of the physical register file
			bus_MEM_out : out std_logic_vector(WIDTH-1 downto 0)																
		);
	end component;

	-- signal declaration
	signal Clk_s, Rst_s, En_s, RD1_s, RD2_s, WR_s, call_subroutine_s, return_subroutine_s, start_seq_MEM_s, ack_MEM_s : std_logic;
	signal Addr_WR_s, Addr_RD1_s, Addr_RD2_s : std_logic_vector(integer(ceil(log2(real(3*N + M) + real(1))))-1 downto 0);
	signal DataIn_s, DataOut1_s, DataOut2_s, bus_MEM_in_s, bus_MEM_out_s : std_logic_vector(WIDTH-1 downto 0);

begin

	DUT : windowedRegisterFile
				generic map(
					N => N,
					M => M,
					F => F,
					WIDTH => WIDTH
				)
				port map(
					Clk => Clk_s,
					Rst => Rst_s,
					En => En_s,
					RD1 => RD1_s,
					RD2 => RD2_s,
					WR => WR_s,
					call_subroutine => call_subroutine_s,
					return_subroutine => return_subroutine_s,
					start_seq_MEM => start_seq_MEM_s,
					ack_MEM => ack_MEM_s,
					Addr_WR => Addr_WR_s,
					Addr_RD1 => Addr_RD1_s,
					Addr_RD2 => Addr_RD2_s,
					DataIn => DataIn_s,
					DataOut1 => DataOut1_s,
					DataOut2 => DataOut2_s,
					bus_MEM_in => bus_MEM_in_s,
					bus_MEM_out => bus_MEM_out_s
				);

	-- clock process
	process
	begin
		Clk_s <= '0';
		wait for 10 ns;
		Clk_s <= '1';
		wait for 10 ns;
	end process;

	-- test process
	process  -- process initialization
	begin
		Rst_s <= '1';
		En_s <= '0';
		RD1_s <= '0';
		RD2_s <= '0';
		WR_s <= '0';
		call_subroutine_s <= '0';
		return_subroutine_s <= '0';
		start_seq_MEM_s <= '0';
		ack_MEM_s <= '0';
		Addr_WR_s <= (others => '0');
		Addr_RD1_s <= (others => '0');
		Addr_RD2_s <= (others => '0');
		DataIn_s <= (others => '0');
		bus_MEM_in_s <= (others => '0');

		wait for 20 ns;

		Rst_s <= '0';
		En_s <= '1';
		
		-- start

-- ===========================================================================================================
--			SUB1
-- ===========================================================================================================

		-- sub#1 IN
		Addr_WR_s <= std_logic_vector(to_unsigned(0, Addr_WR_s'length));	-- write 
		DataIn_s <= x"0C";
		wait for 20 ns;
		WR_s <= '1';
		wait for 60 ns;
		WR_s <= '0';


		Addr_WR_s <= std_logic_vector(to_unsigned(1, Addr_WR_s'length));  -- write
		DataIn_s <= x"0A";
		wait for 20 ns;
		WR_s <= '1';
		wait for 60 ns;
		WR_s <= '0';


		Addr_WR_s <= std_logic_vector(to_unsigned(2, Addr_WR_s'length));	-- write
		DataIn_s <= x"0F";
		wait for 20 ns;
		WR_s <= '1';
		wait for 60 ns;
		WR_s <= '0';


		Addr_WR_s <= std_logic_vector(to_unsigned(3, Addr_WR_s'length));	-- write
		DataIn_s <= x"0E";
		wait for 20 ns;
		WR_s <= '1';
		wait for 60 ns;
		WR_s <= '0';

		-- sub#1 LOCALS

		Addr_WR_s <= std_logic_vector(to_unsigned(9, Addr_WR_s'length));	-- write
		DataIn_s <= x"EE";
		wait for 20 ns;
		WR_s <= '1';
		wait for 60 ns;
		WR_s <= '0';

		-- sub#1 OUT
		Addr_WR_s <= std_logic_vector(to_unsigned(16, Addr_WR_s'length));	-- write
		DataIn_s <= x"A0";
		wait for 20 ns;
		WR_s <= '1';
		wait for 60 ns;
		WR_s <= '0';

		Addr_WR_s <= std_logic_vector(to_unsigned(17, Addr_WR_s'length));	-- write
		DataIn_s <= x"F3";
		wait for 20 ns;
		WR_s <= '1';
		wait for 60 ns;
		WR_s <= '0';

		-- sub#1 GLOBALS
		Addr_WR_s <= std_logic_vector(to_unsigned(24, Addr_WR_s'length));	-- write
		DataIn_s <= x"79";
		wait for 20 ns;
		WR_s <= '1';
		wait for 60 ns;
		WR_s <= '0';

		Addr_WR_s <= std_logic_vector(to_unsigned(25, Addr_WR_s'length));	-- write
		DataIn_s <= x"49";
		wait for 20 ns;
		WR_s <= '1';
		wait for 60 ns;
		WR_s <= '0';

		Addr_WR_s <= std_logic_vector(to_unsigned(26, Addr_WR_s'length));	-- write
		DataIn_s <= x"17";
		wait for 20 ns;
		WR_s <= '1';
		wait for 60 ns;
		WR_s <= '0';

-- ===========================================================================================================
--			SUB2
-- ===========================================================================================================
		-- call
		DataIn_s <= (others => '0');
		call_subroutine_s <= '1';
		wait for 20 ns;
		call_subroutine_s <= '0';
		-- sub#2 
		-- read IN registers
		Addr_RD1_s <= std_logic_vector(to_unsigned(0, Addr_WR_s'length));	-- read1
		Addr_RD2_s <= std_logic_vector(to_unsigned(1, Addr_WR_s'length));	-- read2
		RD1_s <= '1';
		RD2_s <= '1';	
		wait for 70 ns;
		RD1_s <= '0';
		RD2_s <= '0';

		wait for 30 ns;

		Addr_WR_s <= std_logic_vector(to_unsigned(8, Addr_WR_s'length));	-- write
		DataIn_s <= x"56";
		wait for 20 ns;
		WR_s <= '1';
		wait for 60 ns;
		WR_s <= '0';

		Addr_WR_s <= std_logic_vector(to_unsigned(16, Addr_WR_s'length));	-- write
		DataIn_s <= x"CA";
		wait for 20 ns;
		WR_s <= '1';
		wait for 60 ns;
		WR_s <= '0';

		Addr_WR_s <= std_logic_vector(to_unsigned(17, Addr_WR_s'length));	-- write
		DataIn_s <= x"FE";
		wait for 20 ns;
		WR_s <= '1';
		wait for 60 ns;
		WR_s <= '0';

		Addr_WR_s <= std_logic_vector(to_unsigned(18, Addr_WR_s'length));	-- write
		DataIn_s <= x"DA";
		wait for 20 ns;
		WR_s <= '1';
		wait for 60 ns;
		WR_s <= '0';

-- ===========================================================================================================
--			SUB3
-- ===========================================================================================================
		-- call
		DataIn_s <= (others => '0');
		call_subroutine_s <= '1';
		wait for 20 ns;
		call_subroutine_s <= '0';
		-- sub#3
		-- read IN registers
		Addr_RD1_s <= std_logic_vector(to_unsigned(0, Addr_WR_s'length));	-- read1
		Addr_RD2_s <= std_logic_vector(to_unsigned(1, Addr_WR_s'length));	-- read2
		RD1_s <= '1';
		RD2_s <= '1';	
		wait for 70 ns;
		RD1_s <= '0';
		RD2_s <= '0';

		wait for 30 ns;

		-- read IN registers
		Addr_RD1_s <= std_logic_vector(to_unsigned(2, Addr_WR_s'length));	-- read3
		RD1_s <= '1';
		wait for 70 ns;
		RD1_s <= '0';

		wait for 30 ns;

		Addr_WR_s <= std_logic_vector(to_unsigned(11, Addr_WR_s'length));	-- write
		DataIn_s <= x"59";
		wait for 20 ns;
		WR_s <= '1';
		wait for 60 ns;
		WR_s <= '0';

		Addr_WR_s <= std_logic_vector(to_unsigned(18, Addr_WR_s'length));	-- write
		DataIn_s <= x"94";
		wait for 20 ns;
		WR_s <= '1';
		wait for 60 ns;
		WR_s <= '0';

		Addr_WR_s <= std_logic_vector(to_unsigned(19, Addr_WR_s'length));	-- write
		DataIn_s <= x"04";
		wait for 20 ns;
		WR_s <= '1';
		wait for 60 ns;
		WR_s <= '0';

-- ===========================================================================================================
--			SUB4
-- ===========================================================================================================
		-- call
		DataIn_s <= (others => '0');
		call_subroutine_s <= '1';
		wait for 20 ns;
		call_subroutine_s <= '0';
		-- sub#4
		-- read IN registers
		Addr_RD1_s <= std_logic_vector(to_unsigned(2, Addr_WR_s'length));	-- read1
		Addr_RD2_s <= std_logic_vector(to_unsigned(3, Addr_WR_s'length));	-- read2
		RD1_s <= '1';
		RD2_s <= '1';	
		wait for 70 ns;
		RD1_s <= '0';
		RD2_s <= '0';

		wait for 30 ns;


		Addr_WR_s <= std_logic_vector(to_unsigned(10, Addr_WR_s'length));	-- write
		DataIn_s <= x"E9";
		wait for 20 ns;
		WR_s <= '1';
		wait for 60 ns;
		WR_s <= '0';

		Addr_WR_s <= std_logic_vector(to_unsigned(16, Addr_WR_s'length));	-- write
		DataIn_s <= x"A4";
		wait for 20 ns;
		WR_s <= '1';
		wait for 60 ns;
		WR_s <= '0';


	

-- ===========================================================================================================
--			SUB5 
-- ===========================================================================================================
		-- call
		DataIn_s <= (others => '0');
		call_subroutine_s <= '1';
		wait for 20 ns;
		call_subroutine_s <= '0';
		-- sub#5
		-- read IN registers
		Addr_RD1_s <= std_logic_vector(to_unsigned(0, Addr_WR_s'length));	-- read1
		RD1_s <= '1';
		wait for 70 ns;
		RD1_s <= '0';

		wait for 30 ns;



		Addr_WR_s <= std_logic_vector(to_unsigned(10, Addr_WR_s'length));	-- write
		DataIn_s <= x"55";
		wait for 20 ns;
		WR_s <= '1';
		wait for 60 ns;
		WR_s <= '0';

		Addr_WR_s <= std_logic_vector(to_unsigned(22, Addr_WR_s'length));	-- write
		DataIn_s <= x"99";
		wait for 20 ns;
		WR_s <= '1';
		wait for 60 ns;
		WR_s <= '0';

		Addr_WR_s <= std_logic_vector(to_unsigned(23, Addr_WR_s'length));	-- write
		DataIn_s <= x"AE";
		wait for 20 ns;
		WR_s <= '1';
		wait for 60 ns;
		WR_s <= '0';


-- ===========================================================================================================
--			SUB6
-- ===========================================================================================================
		-- call
		DataIn_s <= (others => '0');
		call_subroutine_s <= '1';
		wait for 20 ns;
		call_subroutine_s <= '0';
		-- sub#6
		-- read IN registers
		Addr_RD1_s <= std_logic_vector(to_unsigned(6, Addr_WR_s'length));	-- read1
		Addr_RD2_s <= std_logic_vector(to_unsigned(7, Addr_WR_s'length));	-- read2
		RD1_s <= '1';
		RD2_s <= '1';	
		wait for 70 ns;
		RD1_s <= '0';
		RD2_s <= '0';

		wait for 30 ns;


		Addr_WR_s <= std_logic_vector(to_unsigned(16, Addr_WR_s'length));	-- write
		DataIn_s <= x"44";
		wait for 20 ns;
		WR_s <= '1';
		wait for 60 ns;
		WR_s <= '0';

		Addr_WR_s <= std_logic_vector(to_unsigned(17, Addr_WR_s'length));	-- write
		DataIn_s <= x"42";
		wait for 20 ns;
		WR_s <= '1';
		wait for 60 ns;
		WR_s <= '0';


-- ===========================================================================================================
--			SUB7
-- ===========================================================================================================
		-- call
		DataIn_s <= (others => '0');
		call_subroutine_s <= '1';
		wait for 20 ns;
		call_subroutine_s <= '0';
		-- sub#7
		-- read IN registers
		Addr_RD1_s <= std_logic_vector(to_unsigned(0, Addr_WR_s'length));	-- read1
		Addr_RD2_s <= std_logic_vector(to_unsigned(1, Addr_WR_s'length));	-- read2
		RD1_s <= '1';
		RD2_s <= '1';	
		wait for 70 ns;
		RD1_s <= '0';
		RD2_s <= '0';

		wait for 30 ns;


		Addr_WR_s <= std_logic_vector(to_unsigned(12, Addr_WR_s'length));	-- write
		DataIn_s <= x"33";
		wait for 20 ns;
		WR_s <= '1';
		wait for 60 ns;
		WR_s <= '0';

		Addr_WR_s <= std_logic_vector(to_unsigned(16, Addr_WR_s'length));	-- write
		DataIn_s <= x"55";
		wait for 20 ns;
		WR_s <= '1';
		wait for 60 ns;
		WR_s <= '0';



-- ===========================================================================================================
--			SUB8 
-- ===========================================================================================================
		-- call
		DataIn_s <= (others => '0');
		call_subroutine_s <= '1';
		wait for 20 ns;
		call_subroutine_s <= '0';

		wait for 400 ns; -- dalay needed to spill
		-- sub#8
		-- read IN registers
		Addr_RD1_s <= std_logic_vector(to_unsigned(0, Addr_WR_s'length));	-- read1
		RD1_s <= '1';
		wait for 70 ns;
		RD1_s <= '0';

		wait for 30 ns;


		Addr_WR_s <= std_logic_vector(to_unsigned(12, Addr_WR_s'length));	-- write
		DataIn_s <= x"FA";
		wait for 20 ns;
		WR_s <= '1';
		wait for 60 ns;
		WR_s <= '0';

		Addr_WR_s <= std_logic_vector(to_unsigned(15, Addr_WR_s'length));	-- write
		DataIn_s <= x"CA";
		wait for 20 ns;
		WR_s <= '1';
		wait for 60 ns;
		WR_s <= '0';

		Addr_WR_s <= std_logic_vector(to_unsigned(23, Addr_WR_s'length));	-- write
		DataIn_s <= x"DE";
		wait for 20 ns;
		WR_s <= '1';
		wait for 60 ns;
		WR_s <= '0';



-- ===========================================================================================================
--			SUB9 
-- ===========================================================================================================
		-- call
		DataIn_s <= (others => '0');
		call_subroutine_s <= '1';
		wait for 20 ns;
		call_subroutine_s <= '0';

		wait for 400 ns; -- dalay needed to spill
		-- sub#9
		


		Addr_WR_s <= std_logic_vector(to_unsigned(0, Addr_WR_s'length));	-- write
		DataIn_s <= x"CA";
		wait for 20 ns;
		WR_s <= '1';
		wait for 60 ns;
		WR_s <= '0';

		Addr_WR_s <= std_logic_vector(to_unsigned(1, Addr_WR_s'length));	-- write
		DataIn_s <= x"FE";
		wait for 20 ns;
		WR_s <= '1';
		wait for 60 ns;
		WR_s <= '0';

		Addr_WR_s <= std_logic_vector(to_unsigned(2, Addr_WR_s'length));	-- write
		DataIn_s <= x"69";
		wait for 20 ns;
		WR_s <= '1';
		wait for 60 ns;
		WR_s <= '0';

		Addr_WR_s <= std_logic_vector(to_unsigned(3, Addr_WR_s'length));	-- write
		DataIn_s <= x"13";
		wait for 20 ns;
		WR_s <= '1';
		wait for 60 ns;
		WR_s <= '0';

		Addr_WR_s <= std_logic_vector(to_unsigned(7, Addr_WR_s'length));	-- write
		DataIn_s <= x"DE";
		wait for 20 ns;
		WR_s <= '1';
		wait for 60 ns;
		WR_s <= '0';

		Addr_WR_s <= std_logic_vector(to_unsigned(9, Addr_WR_s'length));	-- write
		DataIn_s <= x"CA";
		wait for 20 ns;
		WR_s <= '1';
		wait for 60 ns;
		WR_s <= '0';




		-- return from sub#9 to sub#8
		return_subroutine_s <= '1';
		wait for 20 ns;
		return_subroutine_s <= '0';
		wait for 60 ns;

		-- return from sub#8 to sub#7
		return_subroutine_s <= '1';
		wait for 20 ns;
		return_subroutine_s <= '0';
		wait for 60 ns;

		-- return from sub#7 to sub#6
		return_subroutine_s <= '1';
		wait for 20 ns;
		return_subroutine_s <= '0';
		wait for 60 ns;

		-- return from sub#6 to sub#5
		return_subroutine_s <= '1';
		wait for 20 ns;
		return_subroutine_s <= '0';
		wait for 60 ns;

		-- return from sub#5 to sub#4
		return_subroutine_s <= '1';
		wait for 20 ns;
		return_subroutine_s <= '0';
		wait for 60 ns;

		-- return from sub#4 to sub#3
		return_subroutine_s <= '1';
		wait for 20 ns;
		return_subroutine_s <= '0';
		wait for 60 ns;

		-- return from sub#3 to sub#2
		return_subroutine_s <= '1';
		wait for 20 ns;
		return_subroutine_s <= '0';
		wait for 60 ns;




		wait for 80 ns;

		start_seq_MEM_s <= '1';						-- fill block of sub#2
		wait for 20 ns;
		start_seq_MEM_s <= '0';
		wait for 10 ns;
		bus_MEM_in_s <= x"A0";
		wait for 20 ns;
		bus_MEM_in_s <= x"F3";
		wait for 20 ns;
		bus_MEM_in_s <= x"00";
		wait for 20 ns;
		bus_MEM_in_s <= x"00";
		wait for 20 ns;
		bus_MEM_in_s <= x"00";
		wait for 20 ns;
		bus_MEM_in_s <= x"00";
		wait for 20 ns;
		bus_MEM_in_s <= x"00";
		wait for 20 ns;
		bus_MEM_in_s <= x"00";
		wait for 20 ns;
		bus_MEM_in_s <= x"56";
		wait for 20 ns;
		bus_MEM_in_s <= x"00";
		wait for 20 ns;
		bus_MEM_in_s <= x"00";
		wait for 20 ns;
		bus_MEM_in_s <= x"00";
		wait for 20 ns;
		bus_MEM_in_s <= x"00";
		wait for 20 ns;
		bus_MEM_in_s <= x"00";
		wait for 20 ns;
		bus_MEM_in_s <= x"00";
		wait for 20 ns;
		ack_MEM_s <= '1';
		bus_MEM_in_s <= x"00";
		wait for 20 ns;
		ack_MEM_s <= '0';


		wait for 100 ns;

		-- sub#2
		-- read IN registers
		Addr_RD1_s <= std_logic_vector(to_unsigned(8, Addr_WR_s'length));	-- read1
		RD1_s <= '1';
		wait for 70 ns;		-- expected value => 56
		RD1_s <= '0';

		wait for 30 ns;



		-- return from sub#8
		return_subroutine_s <= '1';
		wait for 20 ns;
		return_subroutine_s <= '0';

		wait for 90 ns;

		start_seq_MEM_s <= '1';						-- fill block of sub#1
		wait for 20 ns;
		start_seq_MEM_s <= '0';	
		wait for 10 ns;
		bus_MEM_in_s <= x"0C";
		wait for 20 ns;
		bus_MEM_in_s <= x"0A";
		wait for 20 ns;
		bus_MEM_in_s <= x"0F";
		wait for 20 ns;
		bus_MEM_in_s <= x"0E";
		wait for 20 ns;
		bus_MEM_in_s <= x"00";
		wait for 20 ns;
		bus_MEM_in_s <= x"00";
		wait for 20 ns;
		bus_MEM_in_s <= x"00";
		wait for 20 ns;
		bus_MEM_in_s <= x"00";
		wait for 20 ns;
		bus_MEM_in_s <= x"00";
		wait for 20 ns;
		bus_MEM_in_s <= x"EE";
		wait for 20 ns;
		bus_MEM_in_s <= x"00";
		wait for 20 ns;
		bus_MEM_in_s <= x"00";
		wait for 20 ns;
		bus_MEM_in_s <= x"00";
		wait for 20 ns;
		bus_MEM_in_s <= x"00";
		wait for 20 ns;
		bus_MEM_in_s <= x"00";
		wait for 20 ns;
		ack_MEM_s <= '1';
		bus_MEM_in_s <= x"00";

		wait for 20 ns;
		ack_MEM_s <= '0';


		wait for 100 ns;

		-- sub#1
		-- read IN registers
		Addr_RD1_s <= std_logic_vector(to_unsigned(9, Addr_WR_s'length));	-- read1
		RD1_s <= '1';
		wait for 70 ns;  -- expected value => EE
		RD1_s <= '0';

	
		

		wait;
	end process;


end architecture;

configuration CFG_TB_WRF of TB is
for TEST 
	for all : windowedRegisterFile
		use configuration work.CFG_ARCHSTRUCT_WRF;
	end for;
end for;
end configuration;
