library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use work.constants.all;

entity windowedRegisterFile is
	generic(
		F : integer := F_WRF; -- number of windows in the register file
		N : integer := N_WRF; -- number of registers per window (globals excluded)
		M : integer := M_WRF;  -- numeber of global registers
		WIDTH : integer := WIDTHbit_WRF  -- number of bits per register
	);
    port (
		Clk : in std_logic;  -- clock signal
		Rst : in std_logic;  -- reset signal
		En : in std_logic;  -- enable signal
		RD1 : in std_logic;  -- control signal read 1
		RD2 : in std_logic;  -- control signal read 2
		WR : in std_logic;  -- control signal write

		-- from sub routines
		call_subroutine : in std_logic;  -- call signal from subroutine
		return_subroutine : in std_logic;  -- return signal from subroutine

		-- from main memory
		start_seq_MEM : in std_logic;  -- start sequence of registers
		ack_MEM : in std_logic;  -- end sequence of registers

		-- addresses
		Addr_WR : in std_logic_vector(integer(ceil(log2(real(3*N + M) + real(1))))-1 downto 0);    		-- address ports
		Addr_RD1 : in std_logic_vector(integer(ceil(log2(real(3*N + M) + real(1))))-1 downto 0);
		Addr_RD2 : in std_logic_vector(integer(ceil(log2(real(3*N + M) + real(1))))-1 downto 0);

		-- data
		DataIn : in std_logic_vector(WIDTH-1 downto 0);	 -- input port
		DataOut1 : out std_logic_vector(WIDTH-1 downto 0);  -- output port1
		DataOut2 : out std_logic_vector(WIDTH-1 downto 0);  -- output port2

		-- bus with main memory
		bus_MEM_in : in std_logic_vector(WIDTH-1 downto 0);  -- spill/fill on bus on port #2 of the physical register file
		bus_MEM_out : out std_logic_vector(WIDTH-1 downto 0)																
    );
end entity;

architecture ARCHSTRUCT of windowedRegisterFile is

	-- control unit WRF
	component FSMD_WRF is
		generic(
			F : integer := F_WRF; -- number of windows in the register file
			N : integer := N_WRF; -- number of registers per window (globals excluded)
			M : integer := M_WRF  -- numeber of global registers
		);	
		port(
			Clk : in std_logic;  -- clock signal
			Rst_FSMD_WRF : in std_logic;  -- reset for the FSM-D of the WRF
			En_FSMD_WRF : in std_logic;  -- enable for the FSM-D of the WRF
			RD1_FSMD_WRF : in std_logic;  -- read1 control signal
			RD2_FSMD_WRF : in std_logic;  -- read2 control signal
			WR_FSMD_WRF : in std_logic;  -- write control signal
			call_FSMD_WRF : in std_logic;  -- call signal
			return_FSMD_WRF : in std_logic;  -- return signal
			start_seq_FSMD_WRF : in std_logic;  -- signal received from the MAIN memory (stack) when first register is sent (fill operation)
			ack_FSMD_WRF : in std_logic;  -- signal received from the MAIN memory (stack) when the last register is sent (fill operation)

			RD1_FSMD_WRF_out : out std_logic;  -- control signal read1 delivered to the physical RF
			RD2_FSMD_WRF_out : out std_logic;  -- control signal read2 delivered to the physical RF
			WR_FSMD_WRF_out : out std_logic;  -- control signal write delivered to the physical RF

			addr_virt_RD1_FSMD_WRF : in std_logic_vector(integer(ceil(log2(real(3*N + M) + real(1))))-1 downto 0); -- virtual address read port 1
			addr_virt_RD2_FSMD_WRF : in std_logic_vector(integer(ceil(log2(real(3*N + M) + real(1))))-1 downto 0); -- virtual address read port 2
			addr_virt_WR_FSMD_WRF : in std_logic_vector(integer(ceil(log2(real(3*N + M) + real(1))))-1 downto 0); -- virtual address write
			addr_py_RD1_FSMD_WRF : out std_logic_vector(integer(ceil(log2(real(2*N*F + M) + real(1))))-1 downto 0); -- physical address read port 1
			addr_py_RD2_FSMD_WRF : out std_logic_vector(integer(ceil(log2(real(2*N*F + M) + real(1))))-1 downto 0); -- physical address read port 2
			addr_py_WR_FSMD_WRF : out std_logic_vector(integer(ceil(log2(real(2*N*F + M) + real(1))))-1 downto 0) -- physical address write
		);
	end component;


	-- Physical RF
	component registerfile is
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
	end component;

	-- multiplexer for DataIn driving
	component muxN1 is
		generic (
			N : integer := Nbit_MUXN1
		);
		port(
			A : 	in 		std_logic_vector(N-1 downto 0);	-- input A
			B : 	in 		std_logic_vector(N-1 downto 0);	-- input B
			S : 	in 		std_logic;						-- selection signal
			Y : 	out 	std_logic_vector(N-1 downto 0)	-- output
		);
	end component;

	-- internal signals
	signal RD1_WRF, RD2_WRF, WR_WRF : std_logic;
	signal Addr_PY_RD1, Addr_PY_RD2, Addr_PY_WR : std_logic_vector(integer(ceil(log2(real(2*N*F + M) + real(1))))-1 downto 0);
	signal Data_in_RF, data_out_RF: std_logic_vector (width-1 downto 0);

begin

	-- multiplexer for dataIn driving
	mux_dataIn : muxN1
			generic map (
				N => width
			)
			port map (
				A => DataIn,
				B => bus_MEM_in,
				S => WR,
				Y => Data_in_RF
			);

	-- control unit for the windowed register file
	CU_WRF : FSMD_WRF
			generic map(
				F => F,
				N => N,
				M => M
			)
			port map(
				Clk => Clk,
				Rst_FSMD_WRF => Rst,
				En_FSMD_WRF => En,
				RD1_FSMD_WRF => RD1,
				RD2_FSMD_WRF => RD2,
				WR_FSMD_WRF => WR,
				call_FSMD_WRF => call_subroutine,
				return_FSMD_WRF => return_subroutine,
				start_seq_FSMD_WRF => start_seq_MEM,
				ack_FSMD_WRF => ack_MEM,
				RD1_FSMD_WRF_out => RD1_WRF,
				RD2_FSMD_WRF_out => RD2_WRF,
				WR_FSMD_WRF_out => WR_WRF,
				addr_virt_RD1_FSMD_WRF => Addr_RD1,
				addr_virt_RD2_FSMD_WRF  => Addr_RD2,
				addr_virt_WR_FSMD_WRF => Addr_WR,
				addr_py_RD1_FSMD_WRF => Addr_PY_RD1,
				addr_py_RD2_FSMD_WRF => Addr_PY_RD2,
				addr_py_WR_FSMD_WRF => Addr_PY_WR
			);

	RF : registerfile
			generic map(
				N => WIDTH,
				M => integer(ceil(log2(real(2*N*F + M) + real(1))))
			)
			port map(
				Clk => Clk,
				Rst => Rst,
				En => En,
				RD1 => RD1_WRF,
				RD2 => RD2_WRF,
				WR => WR_WRF,
				Addr_WR => Addr_PY_WR,
				Addr_RD1 => Addr_PY_RD1,
				Addr_RD2 => Addr_PY_RD2,
				DataIN => Data_in_RF,
				Out1 => DataOut1,
				Out2 => data_out_RF
			);

	bus_MEM_out<=data_out_RF;
	DataOut2<=data_out_RF;
	

end architecture;

configuration CFG_ARCHSTRUCT_WRF of windowedRegisterFile is
	for ARCHSTRUCT
		for all : FSMD_WRF
			use configuration work.CFG_ARCHSTRUCT_FSMD_WRF;
		end for;

		for all : registerfile
			use configuration work.CFG_RF_BEH;
		end for;

		for all : muxN1
			use configuration work.CFG_MUXN1_ARCHSTRUCT;
		end for;	
	end for;
end configuration;
