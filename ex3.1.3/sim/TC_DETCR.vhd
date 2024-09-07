library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
use work.constants.all;

entity TC_DETCR is
	generic(
		N : integer := Nbit_And;	-- gate and width
		maxVal : integer := MaxVal_UpCnt
	);
	port (
		A : in std_logic_vector(N-1 downto 0); -- input
		TC : out std_logic		-- TC output
	);
end entity;

architecture dataflow of TC_DETCR is
begin

	TC <= and_reduce(A);	-- in order to check if A is made of all 1s 
							-- we can compute the logic AND on all bits
							-- in cascade

end architecture;

architecture beh of TC_DETCR is
begin

	-- process that checks if the input A has a specific value, if
	-- yes it raises the TC to high (output)
	process(A)
	begin
		if (to_integer(unsigned(A)) = maxVal) then
			TC <= '1';
		else
			TC <= '0';
		end if;
	end process;
end architecture;

configuration CFT_ARCHDATAFLOW_TC_DETCR of TC_DETCR is
	for dataflow
	end for;
end configuration;

configuration CFT_ARCHBEH_TC_DETCR of TC_DETCR is
	for beh
	end for;
end configuration;
