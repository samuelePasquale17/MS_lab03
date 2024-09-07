library ieee;
use ieee.std_logic_1164.all;
use work.constants.all;

entity UpCntN is
	generic(
		N : integer := Nbit_UpCnt;
		maxVal : integer := MaxVal_UpCnt
	);
	port (
		Clk : in std_logic;
		Rst : in std_logic;
		cnt : in std_logic;
		Out_cnt : out std_logic_vector(N-1 downto 0);
		TC : out std_logic
	);
end entity;

architecture struct of UpCntN is
	component RegN is
		generic(
			N : integer := Nbit_Reg	-- register width
		);
		port (
			Clk : in std_logic;	-- clock signal
			Rst : in std_logic;	-- reset signal
			en : in std_logic;	-- enable signal
			Out_reg : out std_logic_vector(N-1 downto 0); -- output
			In_reg : in std_logic_vector(N-1 downto 0)		-- input
		);
	end component;

	component TC_DETCR is
		generic(
			N : integer := Nbit_And;	-- gate and width
			maxVal : integer := MaxVal_UpCnt
		);
		port (
			A : in std_logic_vector(N-1 downto 0); 		-- input
			TC : out std_logic	-- TC output
		);
	end component;

	component RCA is
		generic (
			N 	: integer 	:= Nbit_RCA
		);
		port(
			A 	: 	in 		std_logic_vector(N-1 downto 0);
			B 	: 	in 		std_logic_vector(N-1 downto 0);
			Ci 	: 	in 		std_logic;
			S 	: 	out 	std_logic_vector(N-1 downto 0);
			Co 	: 	out 	std_logic
		);
	end component;

	signal tempS, incS : std_logic_vector(N-1 downto 0);
	signal cntRollOver, rst_internal : std_logic;



begin

	Reg : RegN						-- register on N bits 
			generic map(
				N => N
			)
			port map(
				Clk => Clk,
				Rst => rst_internal,
				en => cnt,		-- when count enable is active it loads the incremented value
				Out_reg => tempS,
				In_reg => incS
			);

	Inc : RCA					-- RCA used as incrementer by 1 setting one input to 0 and Ci = 1
			generic map(
				N => N
			)
			port map(
				A => tempS,
				B => (others => '0'),
				Ci => '1',
				S => incS,
				Co => open		-- Carry out not needed
			);

	TC_DETECTOR : TC_DETCR			-- terminal count detector which is 1 when the current status of the counter is made of all 1s
			generic map(
				N => N,
				maxVal => maxVal
			)
			port map(
				A => tempS,
				TC => cntRollOver
			);

	Out_cnt <= tempS;
	TC <= cntRollOver;					-- if the TC_DETECTOR detects the final value we drive the TC output
	rst_internal <= Rst or cntRollOver;	-- and we drive the reset of the register as well
										-- in this manner as soon as we reach the final value the count rools over to 0
										-- ATTENTION! : the correct behavior in terms of timing is correct iff the reset is syncronous 
										--              ... if not we will have a sort of pulse as TC instead of a 1 signal for the entire clock cycle

end architecture;

configuration CFG_ARCHSTRUCT_UPCNT of UpCntN is
	for struct
		for Reg : RegN
			use configuration work.CFT_ARCHBEH_REGN;
		end for;

		for Inc : RCA
			use configuration work.CFG_RCA_ARCHSTRUCT;
		end for;

		for TC_DETECTOR : TC_DETCR
			use configuration work.CFT_ARCHBEH_TC_DETCR;
		end for;
	end for;

end configuration;
