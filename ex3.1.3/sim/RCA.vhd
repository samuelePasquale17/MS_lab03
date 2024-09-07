library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;

entity RCA is
	generic (
		N 	: integer 	:= Nbit_RCA
	);
	port(
		A 	: 	in 		std_logic_vector(N-1 downto 0);
		B 	: 	in 		std_logic_vector(N-1 downto 0);
		Ci 	: 	in 		std_logic;
		S 	: 	out 	std_logic_vector(N-1 downto 0);
		Co 	: 	out 	std_logic
	);
end entity;

-- behavioral description of the RCA
architecture ARCHBEH of RCA is					-- behavioral description
begin
	process (A, B, Ci)
        variable sum : unsigned(N downto 0); -- variable for add two operands
        
	begin
          -- outputs driven with a delay
          sum := unsigned('0' & A) + unsigned('0' & B) + ('0' & Ci);
          -- mapping the sum and the carry out on the variable
          S <= std_logic_vector(sum(N-1 downto 0)) after DelaySum_RCA;
          Co <= sum(N) after DelayCarryOut_RCA;
	end process;


end architecture;


-- structural description of the RCA
architecture ARCHSTRUCT of RCA is

	component FA is
		port(
			A 	: 	in 		std_logic;
			B 	: 	in 		std_logic;
			Ci 	: 	in 		std_logic;
			S 	: 	out 	std_logic;
			Co 	: 	out 	std_logic
		);
	end component;
	
        signal STMP : std_logic_vector(N-1 downto 0); -- vector for the sum
        signal CTMP : std_logic_vector(N downto 0); -- vector for the ripple of
                                                    -- the carry

begin
  CTMP(0) <= Ci; -- mapping vectors with input and outputs
  S <= STMP;
  Co <= CTMP(N);

  ADDER1: for I in 1 to N generate -- loop generate statement
    FAI : FA 
      port map (A(I-1), B(I-1), CTMP(I-1), STMP(I-1), CTMP(I)); 
    end generate;

end architecture;

configuration CFG_RCA_ARCHBEH of RCA is
	for ARCHBEH
	end for;
end configuration;

configuration CFG_RCA_ARCHSTRUCT of RCA is
	for ARCHSTRUCT
          for ADDER1
            for all : FA
              use configuration work.CFG_FA_ARCHBEH;
            end for;
          end for;
	end for;
end configuration;
