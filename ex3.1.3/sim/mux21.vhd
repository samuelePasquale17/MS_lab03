library ieee;
use ieee.std_logic_1164.all;
use work.constants.all;

entity mux21 is
	port(
		A : 	in 		std_logic;
		B : 	in 		std_logic;
		S : 	in 		std_logic;
		Y : 	out 	std_logic
	);
end entity;

architecture ARCHDF1 of mux21 is	-- dataflow architecture
begin
	Y <= (A and S) or (B  and not(S));
end architecture;

architecture ARCHDF2 of mux21 is	-- dataflow architecture with when-else
begin
	Y <= 	A when S = '1' else
			B;
end architecture;

architecture ARCHBEH of mux21 is	-- behavioral
begin
	process(A, B, S) 
	begin
		if (S = '1') then
			Y <= A;
		else
			Y <= B;
		end if;
	end process;
end architecture;

architecture ARCHSTRUCT of mux21 is
	component nd2 is -- nand
		port(
			A : 	in 		std_logic;
			B : 	in		std_logic;
			Y : 	out 	std_logic
		);
	end component;
	
	component iv is -- inverter
		port(
			A : 	in 		std_logic;
			Y : 	out 	std_logic
		);
	end component;
	
	signal n_S, s1, s2 : std_logic;

begin

	NOT1 : iv port map(
					A => S,
					Y => n_S
				);
				
	NAND1 : nd2 port map(
					A => A,
					B => S,
					Y => s1
				);
				
	NAND2 : nd2 port map(
					A => B,
					B => n_S,
					Y => s2
				);
				
	NAND3 : nd2 port map(
					A => s1,
					B => s2,
					Y => Y
				);
				
end architecture;

configuration CFG_MUX21_ARCHDF1 of mux21 is
	for ARCHDF1 
	end for;
end configuration;

configuration CFG_MUX21_ARCHDF2 of mux21 is
	for ARCHDF2 
	end for;
end configuration;

configuration CFG_MUX21_ARCHBEH of mux21 is
	for ARCHBEH
	end for;
end configuration;

configuration CFG_MUX21_ARCHSTRUCT of mux21 is
	for ARCHSTRUCT
		for all : iv 
			use configuration work.CFG_IV_ARCHSTRUCT;
		end for;
		
		for all : nd2 
			use configuration work.CFG_NAND_ARCHSTRUCT;
		end for;
	end for;
end configuration;
