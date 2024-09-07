library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use work.constants.all;

entity RETURN_CHECK_LOGIC is
	generic (
		N : integer := Nbit_return_check_logic -- width of the inputs
	);	
	port (
		CWP : in std_logic_vector(N-1 downto 0);		-- current window pointer
		SWP : in std_logic_vector(N-1 downto 0);		-- saved window pointer
		CANRESTORE : in std_logic_vector(N-1 downto 0); -- can restore window flags
		Can_return : out std_logic						-- Can_return = 1 means that a return subroutine doesn't require a fill from the main memory, 
	);													-- i.e. the previous window is the parent of the current one
end entity;

architecture dataflow of RETURN_CHECK_LOGIC is
begin

	-- can return is 0 if CWP == SWP and previous position in CANRESTORE is 0
	Can_return <= 	'0' when OR_reduce(CWP xor SWP) = '0' and AND_reduce( (CANRESTORE(0) & CANRESTORE(N-1 downto 1)) or not(CWP)) = '0' else
					'1';

end architecture;


configuration CFG_DF_RETURN_CHECK_LOGIC of RETURN_CHECK_LOGIC is
	for dataflow
	end for;
end configuration;
