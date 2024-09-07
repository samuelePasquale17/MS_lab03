library ieee;
use ieee.std_logic_1164.all;
use work.constants.all;

entity FA is			-- full adder
	port(
		A 	: 	in 		std_logic;
		B 	: 	in 		std_logic;
		Ci 	: 	in 		std_logic;
		S 	: 	out 	std_logic;
		Co 	: 	out 	std_logic
	);
end entity;

-- Full Adder

-- behavioral description
architecture ARCHBEH of FA is
begin
        -- delay for both outputs defined into the constant file
	S <= A xor B xor Ci after DelaySum_FA;
	Co <= (A and B) or (A and Ci) or (B and Ci) after DelayCarryOut_FA;
end architecture;

configuration CFG_FA_ARCHBEH of FA is
	for ARCHBEH
	end for;
end configuration;
