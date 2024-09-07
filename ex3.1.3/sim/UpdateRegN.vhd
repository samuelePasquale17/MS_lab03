library ieee;
use ieee.std_logic_1164.all;
use work.constants.all;


entity UpdateRegN is
	generic(
		N : integer := Nbit_UpdateRegN
	);
	port (
		load : in std_logic;								-- control signal for load the dataIn
		updateOR : in std_logic;							-- control signal to set = 1 a flag
		updateAND : in std_logic;							-- control signal to clear = 0 a flag
		Clk : in std_logic;
		dataIn : in std_logic_vector(N-1 downto 0);
		dataOut : out std_logic_vector(N-1 downto 0);
		updateVal : in std_logic_vector(N-1 downto 0)		-- it should be driven with CWP or SWP to set/clear a flag
	);
end entity;

architecture struct of UpdateRegN is
	
	component RegN is							-- internal register 
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
	end component;

	component muxN1 is						-- multiplexer
		generic (N : integer := Nbit_MUXN1);
		port(
			A : 	in 		std_logic_vector(N-1 downto 0);	-- input A
			B : 	in 		std_logic_vector(N-1 downto 0);	-- input B
			S : 	in 		std_logic;						-- selection signal
			Y : 	out 	std_logic_vector(N-1 downto 0)	-- output
		);
	end component;

	component or2N is		-- or gate
		generic(
			N : integer := 1	-- by default it is a 1-bit logic gate
		);
		port(
			A : in std_logic_vector(N-1 downto 0);
			B : in std_logic_vector(N-1 downto 0);
			Y : out std_logic_vector(N-1 downto 0)
		);
	end component;

	component not2N is			-- inverter
		generic(
			N : integer := 1	-- by default it is a 1-bit logic gate
		);
		port(
			A : in std_logic_vector(N-1 downto 0);
			Y : out std_logic_vector(N-1 downto 0)
		);
	end component;

	component and2N is			-- and gate
		generic(
			N : integer := 1	-- by default it is a 1-bit logic gate
		);
		port(
			A : in std_logic_vector(N-1 downto 0);
			B : in std_logic_vector(N-1 downto 0);
			Y : out std_logic_vector(N-1 downto 0)
		);
	end component;

	signal update, enReg_sig : std_logic;
	signal inReg_sig, out_update_sig, out_update_or, out_update_not, out_update_and, outReg_sig : std_logic_vector(N-1 downto 0);


begin

	orUpdate_ctrl_sig : or2N					-- or gate that checks if at least one control update signal is active
			generic map (
				N => 1
			)
			port map(
				A(0) => updateAND,
				B(0) => updateOR,
				Y(0) => update
			);

	orEnableReg : or2N							-- or gate that cehcks if update or load signal is active, if yes means that
			generic map (						-- the register must store the data in
				N => 1
			)
			port map(
				A(0) => update,
				B(0) => load,
				Y(0) => enReg_sig
			);	

	orUpdate : or2N	
			generic map (						-- or that implements the following operation newState = currState + window_pointer
				N => N							-- this operation allows to set (=1) a flag of the current state of the register
			)
			port map(
				A => updateVal,
				B => outReg_sig,
				Y => out_update_or
			);

	invUpdateVal : not2N
			generic map (					-- inverting the update value driven as input... it will be anded with the current state				
				N => N							
			)
			port map(
				A => updateVal,
				Y => out_update_not
			);

	andUpdateVal : and2N					-- anding the update inverted value in order to clear a flag of the current state (=0)
			generic map (						
				N => N
			)
			port map(
				A => outReg_sig,
				B => out_update_not,
				Y => out_update_and
			);	

	muxUpdate : muxN1						-- mux that based on the selected update control signal activated selects one of the two 
			generic map(					-- updated outputs
				N => N
			)
			port map(
				A => out_update_or,
				B => out_update_and,
				S => updateOR,
				Y => out_update_sig
			);

	muxDataIn : muxN1						-- mux that selects 2 signals and drives one of these two as dataIN of the register
			generic map(					 
				N => N
			)
			port map(
				A => out_update_sig,
				B => dataIn,
				S => update,
				Y => inReg_sig
			);

	reg : RegN 
			generic map(
				N => N
			)
			port map(
				Clk => Clk,
				Rst => '0',
				en => enReg_sig,
				Out_reg => outReg_sig,
				In_reg => inReg_sig
			);

	dataOut <= outReg_sig;



end architecture;

configuration CFG_ARCHSTRUCT_UpdateRegN of UpdateRegN is
	for struct
		for all : RegN
			use configuration work.CFT_ARCHBEH_REGN;
		end for;

		for all : muxN1
			use configuration work.CFG_MUXN1_ARCHSTRUCT;
		end for;

		for all : or2N
			use configuration work.CFG_ARCHDATAFLOW_or2N;
		end for;

		for all : not2N
			use configuration work.CFG_ARCHDATAFLOW_not2N;
		end for;

		for all : and2N
			use configuration work.CFG_ARCHDATAFLOW_and2N;
		end for;
	end for;
end configuration;
