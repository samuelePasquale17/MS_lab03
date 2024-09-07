library ieee;
use ieee.std_logic_1164.all;
use work.constants.all;

entity not2N is
	generic(
		N : integer := 1	-- by default it is a 1-bit logic gate
	);
	port(
		A : in std_logic_vector(N-1 downto 0);
		Y : out std_logic_vector(N-1 downto 0)
	);
end entity;

architecture dataflow of not2N is
begin
	
	Y <= not(A); -- or gate

end architecture;

configuration CFG_ARCHDATAFLOW_not2N of not2N is
for dataflow
end for;
end configuration;
