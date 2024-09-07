library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;



entity TBREGISTERFILE is
end TBREGISTERFILE;

architecture TB of TBREGISTERFILE is

	component registerfile is
		generic (
			N : integer := Nbit_registerfile;                       -- number of bits per each register   
			M : integer := Nbit_addressRF                        -- number of registers
		);
		port (
			Clk :       in std_logic;                               -- Clock signal
			Rst :       in std_logic;                               -- Reset signal active high
			En  :       in std_logic;                               -- Enable signal active high

			RD1 :       in std_logic;                               -- Read enable signals for read1 and read2 active high
			RD2 :       in std_logic;

			WR :        in std_logic;                               -- Write enable signal active high

			Addr_WR :   in std_logic_vector(M-1 downto 0);    -- address ports
			Addr_RD1 :  in std_logic_vector(M-1 downto 0);
			Addr_RD2 :  in std_logic_vector(M-1 downto 0);
			
			DataIN :    in std_logic_vector(N-1 downto 0);          -- data input port

			Out1 :      out std_logic_vector(N-1 downto 0);         -- data output ports
			Out2 :      out std_logic_vector(N-1 downto 0)

		);
	end component;



	constant N_s : integer := 8; -- 32-bit registers
	constant M_s : integer := 8;  -- 8 bits for addresses

	-- signals declaration
		
    signal Clk_s: std_logic;
    signal Rst_s: std_logic;
    signal En_s: std_logic;
    signal RD1_s: std_logic;
    signal RD2_s: std_logic;
    signal WR_s: std_logic;
    signal Addr_WR_s: std_logic_vector(M_s-1 downto 0);
    signal Addr_RD1_s: std_logic_vector(M_s-1 downto 0);
    signal Addr_RD2_s: std_logic_vector(M_s-1 downto 0);
    signal DataIN_s: std_logic_vector(N_s-1 downto 0);
    signal Out1_s : std_logic_vector(N_s-1 downto 0);
    signal Out2_s : std_logic_vector(N_s-1 downto 0);




begin 


	DUT : registerfile
		generic map(
			N => N_s,
			M => M_s
		)
		port map(
			Clk => Clk_s,
			Rst => Rst_s,   
			En => En_s,

			RD1 => RD1_s,
			RD2 => RD2_s,

			WR => WR_s,  

			Addr_WR =>  Addr_WR_s, 
			Addr_RD1 => Addr_RD1_s,
			Addr_RD2 => Addr_RD2_s,
			
			DataIN => DataIN_s,

			Out1 => Out1_s,
			Out2 => Out2_s
		);


	
	

	clkProc : process		-- clock source process
	begin
		Clk_s <= '0';
		wait for 10 ns;
		Clk_s <= '1';
		wait for 10 ns;
	end process;

	process 
	begin
		Rst_s <= '1';
		En_s <= '0';
		RD1_s <= '0';
		RD2_s <= '0';
		WR_s <= '0';
		Addr_WR_s <= "00000000"; 
		Addr_RD1_s <= "00000000";  
		Addr_RD2_s <= "00000000";
		DataIN_s <= X"00";

		wait for 20 ns;

		En_s <= '1';
		Rst_s <= '0';
		Addr_WR_s <= "00000000";
		DataIN_s <= X"0C";

		wait for 10 ns;
		WR_s <= '1';
		

		wait for 10 ns;

		
		WR_s <= '1';
		Addr_WR_s <= "00000001";
		DataIN_s <= X"0A";

		wait for 20 ns;

	
		WR_s <= '1';
		Addr_WR_s <= "00000010";
		DataIN_s <= X"0F";

		wait for 20 ns;


		WR_s <= '1';
		Addr_WR_s <= "00000011";
		DataIN_s <= X"0E";

		wait for 20 ns;

		WR_s <= '0';	

		wait for 20 ns;
		RD1_s <= '1';
		RD2_s <= '1';


		Addr_RD1_s <= "00000000";  
		Addr_RD2_s <= "00000001";

		wait for 20 ns;
		Addr_RD1_s <= "00000010";  
		Addr_RD2_s <= "00000011";
		



		wait;
	end process;
end TB;


configuration CFG_TEST_RF of TBREGISTERFILE is
	for TB
		for DUT : registerfile
			use configuration work.CFG_RF_BEH;
		end for;
	end for;
end configuration;
