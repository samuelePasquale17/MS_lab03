package constants is
    -- Default number of bits --

    constant Nbit_MUXN1                 : integer := 4;     -- MUX Nto1
    constant Nbit_RCA                   : integer := 4;     -- RCA
    constant Nbit_carry_select_block    : integer := 4;     -- CARRY SELECT BLOCK
    constant Nbit_sum_generator         : integer := 32;    -- SUM GENERATOR
    constant Nbit_pg_network            : integer := 32;    -- PG NETWORK
    constant Nbit_carry_generator       : integer := 32;    -- CARRY GENERATOR
    constant Nbit_p4_adder              : integer := 32;    -- P4 ADDER
    constant Nbit_boothmul              : integer := 32;    -- BOOTH MUL
    constant Nbit_mux8to1               : integer := 4;     -- MUL 8 inputs to 1 output
    constant Nbit_booth_encoder         : integer := 32;    -- ENCODER BOOTH
	constant Nbit_shift_pow2			: integer := 32;	-- SHIFT POW 2
	constant Nbit_complementor			: integer := 32;	-- COMPLEMENTOR
    constant Nbit_registerfile          : integer := 64;    -- REGISTER FILE WIDTH
    constant Nbit_addressRF             : integer := 5;     -- REGISTER FILE nsum bit address line
	constant Nbit_RotReg				: integer := 32;	-- ROTATE REGISTER
	constant Nbit_UpCnt					: integer := 8;		-- UP COUNTER
	constant Nbit_Reg					: integer := 32;	-- REGISTER 
	constant Nbit_And					: integer := 8;		-- AND GATE 
	constant Nbit_call_check_logic		: integer := 8;		-- CALL CHECK LOGIC
	constant Nbit_return_check_logic	: integer := 8;		-- RETURN CHECK LOGIC
	constant Nbit_RST_ROM				: integer := 8;		-- RESET ROM for SWP,CWP,CANSAVE,CANRETURN
	constant Nbit_UpdateRegN			: integer := 8;		-- Update RegN
	constant MaxVal_UpCnt				: integer := 10;	-- max count val for up counter
	constant N_WRF						: integer := 8;		-- number of registers per window in  register file
	constant M_WRF						: integer := 3;		-- number of global registers in windowed register file
	constant F_WRF						: integer := 8;		-- number of windows in windowed register file
	constant WIDTHbit_WRF				: integer := 32;	-- number of bits per register in windowed register file
	
    -- Default delay values --


    -- NOT
    constant IVDELAY : time := 0 ns; -- NOT output delay

    -- NAND
    constant NDDELAY : time := 0 ns; -- NAND output delay

    -- XOR 
    constant XORDELAY : time := 0 ns;   -- XOR output delay

    -- AND 
    constant ANDDELAY : time := 0 ns;   -- AND output delay

    -- PG and G block
    constant PDELAY : time := 0 ns;     -- Propagate delay
    constant GDELAY : time := 0 ns;     -- Generate delay


    -- RCA
    constant DelaySum_RCA       : time := 0 ns;         -- RCA Sum
    constant DelayCarryOut_RCA  : time := 0 ns;         -- RCA Carry Out

    -- FA
    constant DelaySum_FA        : time := 0 ns;         -- FA Sum
    constant DelayCarryOut_FA   : time := 0 ns;         -- FA Carry Out

    -- Register File
    constant DelayOutputPort    : time := 0 ns;


end constants;
