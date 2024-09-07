library ieee;
use ieee.std_logic_1164.all;
use work.constants.all;

entity RegN is
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
end entity;

architecture beh of RegN is
signal state : std_logic_vector(N-1 downto 0); -- inner state of the register

begin
	process (Clk, Rst) 	-- sensitive to clk and rst only
	begin
		if(rising_edge(Clk)) then
			if (Rst = '1') then
				state <= (others => '0');	-- zeroed-out
			elsif (en = '1') then
				state <= In_reg;		-- load the input
			end if;
		end if;
	end process;

	Out_reg <= state;

end architecture;

configuration CFT_ARCHBEH_REGN of RegN is
	for beh
	end for;
end configuration;
