library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.constants.all;


entity registerfile is
    generic (
        N : integer := Nbit_registerfile;                       -- number of bits per each register   
        M : integer := Nbit_addressRF                           -- number of bits for address line (#registers = 2**M)
    );
    port (
        Clk :       in std_logic;                              -- Clock signal
        Rst :       in std_logic;                               -- Reset signal active high
        En  :       in std_logic;                               -- Enable signal active high

        RD1 :       in std_logic;                               -- Read enable signals for read1 and read2 active high
        RD2 :       in std_logic;

        WR :        in std_logic;                               -- Write enable signal active high

        Addr_WR :   in std_logic_vector(M-1 downto 0);    		-- address ports
        Addr_RD1 :  in std_logic_vector(M-1 downto 0);
        Addr_RD2 :  in std_logic_vector(M-1 downto 0);
        
        DataIN :    in std_logic_vector(N-1 downto 0);          -- data input port

        Out1 :      out std_logic_vector(N-1 downto 0);         -- data output ports
        Out2 :      out std_logic_vector(N-1 downto 0)

    );
end entity;

architecture ARCHBEH of registerfile is
    subtype REG_ADDR is natural range 0 to 2**M-1; -- use natural type
	type REG_ARRAY is array(REG_ADDR) of std_logic_vector(N-1 downto 0); 
	signal REGISTERS : REG_ARRAY; 

	
begin 
	process(Clk) 
	begin
		if(rising_edge(Clk))then  -- rising edge of the clock event
			if(Rst='1')then
				REGISTERS <= (others => (others => '0'));  -- reset the register file status
				Out1 <= (others=>'0');
				Out2 <= (others=>'0');
			else
				if(En='1')then
					if(RD1='1')then
						Out1<=REGISTERS(to_integer(unsigned(Addr_RD1)));  -- read on port 1
					end if;
					if(RD2='1')then
						Out2<=REGISTERS(to_integer(unsigned(Addr_RD2)));  -- read on port 2
					end if;
					if(WR='1')then
						REGISTERS(to_integer(unsigned(Addr_WR)))<=DataIn;  -- write
					end if;
				end if;
			end if;
		end if;

	end process;
end architecture;


configuration CFG_RF_BEH of registerfile is
    for ARCHBEH
    end for;
end configuration;
