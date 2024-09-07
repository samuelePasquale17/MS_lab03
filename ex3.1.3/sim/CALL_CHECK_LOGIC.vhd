library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use work.constants.all;

entity CALL_CHECK_LOGIC is
	generic (
		N : integer := Nbit_call_check_logic -- width of the inputs
	);	
	port (
		CWP : in std_logic_vector(N-1 downto 0);		-- current window pointer
		CANSAVE : in std_logic_vector(N-1 downto 0);	-- can save window flags
		Free : out std_logic							-- Free = 1 means that the window is free and we can call without spill into the memory the registers 
	);													-- otherwise spill
end entity;

architecture dataflow of CALL_CHECK_LOGIC is
begin

	-- checking if 2 windows forward the window have been already used by another subroutine
	Free <= or_reduce(CWP and (CANSAVE(N-3 downto 0) & CANSAVE(N-1 downto N-2)));

end architecture;

configuration CFG_DF_CALL_CHECK_LOGIC of CALL_CHECK_LOGIC is
	for dataflow
	end for;
end configuration;
