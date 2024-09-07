library ieee; 
use ieee.std_logic_1164.all;
use work.constants.all;

entity RotRegN is
	generic(
		N : integer := Nbit_RotReg
	);
	port(
		DataIn : in std_logic_vector(N-1 downto 0);	-- data input for the parallel load
		Clk : in std_logic;	-- clock signal
		Rst : in std_logic; -- reset signal
		Load : in std_logic;	-- parallel load enable signal
		RotL : in std_logic; -- rotate left by 1
		RotR : in std_logic;	-- rotate right by 1
		DataOut : out std_logic_vector(N-1 downto 0) -- output data
	);
end entity;

architecture beh of RotRegN is
signal state : std_logic_vector(N-1 downto 0);

begin

	process(Rst, Clk)
	begin
		if (Rst = '1') then
			state <= (others => '0'); -- if rst active, zeroed-out the content
		elsif (rising_edge(Clk)) then
			if (Load = '1') then	
				state <= DataIn;	-- parallel load
			elsif(RotL = '1') then
				state <= state(N-2 downto 0) & state(N-1); -- shift left by 1
			elsif(RotR = '1') then
				state <= state(0) & state(N-1 downto 1);	-- shift right by 1
			end if;
		end if;
	end process;

	DataOut <= state;	-- drivin the inner state as output
end architecture;

configuration CFT_ARCHBEH_RotRegN of RotRegN is
	for beh
	end for;
end configuration;
