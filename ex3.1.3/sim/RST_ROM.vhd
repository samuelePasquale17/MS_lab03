library ieee;
use ieee.std_logic_1164.all;
use work.constants.all;

entity RST_ROM is
	generic(
		N : integer := Nbit_RST_ROM
	);
	port (
		en : in std_logic; -- enable signal
		SWP_rst_val : out  std_logic_vector(N-1 downto 0);
		CWP_rst_val : out  std_logic_vector(N-1 downto 0);
		CANSAVE_rst_val : out  std_logic_vector(N-1 downto 0);
		CANRETURN_rst_val : out  std_logic_vector(N-1 downto 0)
	);
end entity;

architecture dataflow of RST_ROM is
begin

	SWP_rst_val(N-1) <= '1' when en = '1' else
						'0';										-- at the beginning the saved window pointer points to the first window
	SWP_rst_val(N-2 downto 0) <= (others => '0');

	CWP_rst_val(N-1) <= '1' when en = '1' else
						'0';										-- at the beginning the current window pointer points to the first window
	CWP_rst_val(N-2 downto 0) <= (others => '0');


	CANSAVE_rst_val <= 	(others => '1') when en = '1' else		-- at the beginning all windows are free
						(others => '0');
	
	CANRETURN_rst_val <= 	(others => '1') when en = '1' else	-- at the beginiing it is possible to return since no spill have been done before
							(others => '0');

end architecture;


configuration CFG_ARCHDATAFLOW_RST_ROM of RST_ROM is
	for dataflow
	end for;
end configuration;
