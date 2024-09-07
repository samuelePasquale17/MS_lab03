library ieee;
use ieee.std_logic_1164.all;
use work.constants.all;

entity or2N is
	generic(
		N : integer := 1	-- by default it is a 1-bit logic gate
	);
	port(
		A : in std_logic_vector(N-1 downto 0);
		B : in std_logic_vector(N-1 downto 0);
		Y : out std_logic_vector(N-1 downto 0)
	);
end entity;

architecture dataflow of or2N is
begin
	
	Y <= A or B; -- or gate

end architecture;

configuration CFG_ARCHDATAFLOW_or2N of or2N is
for dataflow
end for;
end configuration;
