library ieee;
use ieee.std_logic_1164.all;
use work.constants.all;

entity nd2 is -- nand
	port(
		A : 	in 		std_logic;
		B : 	in		std_logic;
		Y : 	out 	std_logic
	);
end entity;

architecture ARCHSTRUC of nd2 is		-- structural 
begin
	Y <= not(A and B) after NDDELAY;	
end architecture;

architecture ARCHBEH of nd2 is
begin
	process (A, B)
	begin
		if (A = '1' and B = '1') then
			Y <= '0';
		else 
			Y <= '1';
		end if;
	end process;
	
end architecture;

configuration CFG_NAND_ARCHSTRUCT of nd2 is -- configuration for structural architecture
	for ARCHSTRUC
	end for;
end configuration;

configuration CFG_NAND_ARCHBEH of nd2 is -- configuration for behavioral architecture
	for ARCHBEH
	end for;
end configuration;