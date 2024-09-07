library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use work.constants.all;

entity FSMD_WRF is
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
end entity;

architecture ARCHSTRUCT of FSMD_WRF is

	--Control Unit
	component CU_FSM_WRF is
		port (
			-- INPUT SIGNALs

			Clk : in std_logic;		-- clock signal
			Rst_CU_FSM_WRF : in std_logic;	-- reset signal
			En_CU_FSM_WRF : in std_logic;	-- enable signal of the entire FSM
	
			-- Read/write control signal received as input from the top entity of the WRF
			RD1_CU_FSM_WRF_in : in std_logic;	
			RD2_CU_FSM_WRF_in : in std_logic;
			WR_CU_FSM_WRF_in : in std_logic;	
	
			-- signals received from the subroutines
			call_ctrl : in std_logic;	-- call
			return_ctrl : in std_logic; -- return

			-- signals received from the datapath
			TC_upcnt : in std_logic;	-- terminal count of the counter
			free : in std_logic;		-- no spill needed when active
			can_return : in std_logic;	-- no fill needed when active		

			-- signals received from the main memory
			start_seq : in std_logic;
			ack : in std_logic;

			-- OUTPUT SIGNALs

			-- read/write control signals driven to the datapath
			RD1_CU_FSM_WRF_out : out std_logic;	
			RD2_CU_FSM_WRF_out : out std_logic;
			WR_CU_FSM_WRF_out : out std_logic;

			-- signals sent to the datapath
			en_rst_rom : out std_logic;		-- enable signal for the ROM that contains the reset values
			load_reg_cwp : out std_logic;	-- load signal for CWP
			load_reg_swp : out std_logic;	-- load signal for SWP
			load_reg_cansave : out std_logic;	-- load signal for CANSAVE
			load_reg_canreturn : out std_logic; -- load signal for CANRETURN
			en_lut_rom : out std_logic;  -- enable signal for the LUT that manages the virtual-to-physical address translation 
			fill_flag : out std_logic;

			-- control signals for up counter
			rst_upcnt : out std_logic; -- signal for reset (zeroed-out) the up counter
			cnt_upcnt : out std_logic; -- signal that, if active, increments the counter status by 1 on the rising edge of the clock

			-- control signals for rotate left/right CWP and SWP
			rotL_CWP : out std_logic;
			rotR_CWP : out std_logic;
			rotL_SWP : out std_logic;
			rotR_SWP : out std_logic;

			-- signal for updating CANSAVE or CANRETURN
			-- if *_or activated that means that one flag will be setled to 1 without touching all the others
			-- if *_and activated that means that one flag will be cleared (=0) without touching the others... In order
			-- to avoid to modify all the other signals the val drivens as input is inverted, in this way since the input 
			-- val can be SWP or CWP only actually we get all 1s (thus not modifing anything) except for one the is 0
			cansave_update_and : out std_logic;
			cansave_update_or : out std_logic;
			canreturn_update_and : out std_logic;
			canreturn_update_or : out std_logic;

			spill_fill_flg : out std_logic; -- control signal which tells that the spill or fill operation is going on

			addr_virt_sel_port1 : out std_logic -- control signal driven to a multiplexer that allows to drive
												-- either the virtual read address 1 or the virtual write address to the
												-- LUT for the translation to the proper physical address. If 1 means that we 
												-- are selecting the write address and driving it into the port1 of the LUT_ROM. Otherwise
												-- if 0 means that the selected address is the one for the operation read on port 1
		);
	end component;

	-- Datapath
	component DP_FSM_WRF is
		generic (
			F : integer := F_WRF; -- number of windows in the register file
			N : integer := N_WRF; -- number of registers per window (globals excluded)
			M : integer := M_WRF  -- numeber of global registers
			-- Address sizing:
			-- ceil(log2(real(3*N + M) + real(1))) is the address size for the virtual address, +1 to avoid rounding errors. e.g.: when value = 8s
			-- ceil(log2(real(2*N*F + M) + real(1))); -- is the address size for the physical address, +1 to avoid rounding errors. e.g.: when value = 8s
		);
		port (
			Clk : in std_logic;  -- clock signal

			-- input control signals
			load_reg_swp : in std_logic;  -- load signal for SWP register
			load_reg_cwp : in std_logic;  -- load signal for CWP register
			addr_virt_sel_port_1 : in std_logic;  -- control signal which selects RD1 or WR virtual address and drives it through a mux to the port 1 of the LUT
			rotL_swp : in std_logic;  -- rotation signals for SWP and CWP
			rotR_swp : in std_logic;
			rotL_cwp : in std_logic;
			rotR_cwp : in std_logic;
			load_reg_canreturn : in std_logic;  -- load signal for CANRETURN register
			load_reg_cansave : in std_logic;  -- load signal for CANSAVE register
			cansave_update_or : in std_logic;  -- update signals for CANSAVE and CANRETURN ... see CU_FSM_WRF for their behavior description
			cansave_update_and : in std_logic;
			canreturn_update_or : in std_logic;
			canreturn_update_and : in std_logic;
			en_rst_rom : in std_logic;  -- enable signal for the reset ROM, containing the reset values for CWP, SWP, CANSAVE, CANRETURN
			en_lut_rom : in std_logic;	-- anable signal for the LUT ROM, when active either the CWP or the SWP is driven as enable, otherwise zeroed-out by the and gate
			spill_fill_flag : in std_logic;  -- signal active when a fill or spill operation occurs
			cnt_upcnt : in std_logic;  -- signal which, when active, increases by 1 the counter status
			rst_upcnt : in std_logic;  -- signal which resets the up counter status (zeroed-out)
			fill_flag : in std_logic;

			-- output control signals
			can_return : out std_logic;  -- control signal that tells if a return needs (=0) a fill or not (=1)
			free : out std_logic;  -- control signal that tells if a call needs (=0) a spill or not (=1)
			TC_upcnt : out std_logic;  -- terminal count signal sent by the up counter 

			-- input data
			addr_virt_RD1 : in std_logic_vector(integer(ceil(log2(real(3*N + M) + real(1))))-1 downto 0); -- virtual address read port 1
			addr_virt_RD2 : in std_logic_vector(integer(ceil(log2(real(3*N + M) + real(1))))-1 downto 0); -- virtual address read port 2
			addr_virt_WR : in std_logic_vector(integer(ceil(log2(real(3*N + M) + real(1))))-1 downto 0); -- virtual address write

			-- output data
			addr_py_RD1 : out std_logic_vector(integer(ceil(log2(real(2*N*F + M) + real(1))))-1 downto 0); -- physical address read port 1
			addr_py_RD2 : out std_logic_vector(integer(ceil(log2(real(2*N*F + M) + real(1))))-1 downto 0); -- physical address read port 2
			addr_py_WR : out std_logic_vector(integer(ceil(log2(real(2*N*F + M) + real(1))))-1 downto 0) -- physical address write
		);
	end component;

	-- internal signals
	signal TC_upcnt_FSMD_WRF, free_FSMD_WRF, canreturn_FSMD_WRF, en_rst_rom_FSMD_WRF, en_lut_rom_FSMD_WRF, fill_flag_WRF : std_logic;
	signal load_reg_cwp_FSMD_WRF, load_reg_swp_FSMD_WRF, load_reg_cansave_FSMD_WRF, load_reg_canreturn_FSMD_WRF : std_logic;
	signal rst_upcnt_FSMD_WRF, cnt_upcnt_FSMD_WRF, rotL_CWP_FSMD_WRF, rotR_CWP_FSMD_WRF, rotL_SWP_FSMD_WRF, rotR_SWP_FSMD_WRF : std_logic;
	signal cansave_update_and_FSMD_WRF, cansave_update_or_FSMD_WRF, canreturn_update_and_FSMD_WRF, canreturn_update_or_FSMD_WRF : std_logic;
	signal spill_fill_flg_FSMD_WRF, addr_virt_sel_port1_FSMD_WRF : std_logic;


begin

	-- control unit
	CU : CU_FSM_WRF
			port map(
				Clk => Clk,
				Rst_CU_FSM_WRF => Rst_FSMD_WRF,
				En_CU_FSM_WRF => En_FSMD_WRF,
				RD1_CU_FSM_WRF_in => RD1_FSMD_WRF,
				RD2_CU_FSM_WRF_in => RD2_FSMD_WRF,
				WR_CU_FSM_WRF_in => WR_FSMD_WRF,
				call_ctrl => call_FSMD_WRF,
				return_ctrl => return_FSMD_WRF,
				TC_upcnt => TC_upcnt_FSMD_WRF,
				free => free_FSMD_WRF,
				can_return => canreturn_FSMD_WRF,
				start_seq => start_seq_FSMD_WRF,
				ack => ack_FSMD_WRF,
				RD1_CU_FSM_WRF_out => RD1_FSMD_WRF_out,
				RD2_CU_FSM_WRF_out => RD2_FSMD_WRF_out,
				WR_CU_FSM_WRF_out => WR_FSMD_WRF_out,
				en_rst_rom => en_rst_rom_FSMD_WRF,
				load_reg_cwp => load_reg_cwp_FSMD_WRF,
				load_reg_swp => load_reg_swp_FSMD_WRF,
				load_reg_cansave => load_reg_cansave_FSMD_WRF,
				load_reg_canreturn => load_reg_canreturn_FSMD_WRF,
				en_lut_rom => en_lut_rom_FSMD_WRF,
				rst_upcnt => rst_upcnt_FSMD_WRF,
				cnt_upcnt => cnt_upcnt_FSMD_WRF,
				rotL_CWP => rotL_CWP_FSMD_WRF,
				rotR_CWP => rotR_CWP_FSMD_WRF,
				rotL_SWP => rotL_SWP_FSMD_WRF,
				rotR_SWP => rotR_SWP_FSMD_WRF,
				cansave_update_and => cansave_update_and_FSMD_WRF,
				cansave_update_or => cansave_update_or_FSMD_WRF,
				canreturn_update_and => canreturn_update_and_FSMD_WRF,
				canreturn_update_or => canreturn_update_or_FSMD_WRF,
				spill_fill_flg => spill_fill_flg_FSMD_WRF,
				addr_virt_sel_port1 => addr_virt_sel_port1_FSMD_WRF,
				fill_flag => fill_flag_WRF
			);

	-- datapath
	DP : DP_FSM_WRF
			generic map(
				N => N,
				M => M,
				F => F
			)
			port map(
				Clk => Clk,
				load_reg_swp => load_reg_swp_FSMD_WRF,
				load_reg_cwp => load_reg_cwp_FSMD_WRF,
				addr_virt_sel_port_1 => addr_virt_sel_port1_FSMD_WRF,
				rotL_swp => rotL_SWP_FSMD_WRF,
				rotR_swp => rotR_SWP_FSMD_WRF,
				rotL_cwp => rotL_CWP_FSMD_WRF,
				rotR_cwp => rotR_CWP_FSMD_WRF,
				load_reg_canreturn => load_reg_canreturn_FSMD_WRF,
				load_reg_cansave => load_reg_cansave_FSMD_WRF,
				cansave_update_or => cansave_update_or_FSMD_WRF,
				cansave_update_and => cansave_update_and_FSMD_WRF,
				canreturn_update_or => canreturn_update_or_FSMD_WRF,
				canreturn_update_and => canreturn_update_and_FSMD_WRF,
				en_rst_rom => en_rst_rom_FSMD_WRF,
				en_lut_rom => en_lut_rom_FSMD_WRF,
				spill_fill_flag => spill_fill_flg_FSMD_WRF,
				cnt_upcnt => cnt_upcnt_FSMD_WRF,
				rst_upcnt => rst_upcnt_FSMD_WRF,
				can_return => canreturn_FSMD_WRF,
				free => free_FSMD_WRF,
				TC_upcnt => TC_upcnt_FSMD_WRF,
				addr_virt_RD1 => addr_virt_RD1_FSMD_WRF,
				addr_virt_RD2 => addr_virt_RD2_FSMD_WRF,
				addr_virt_WR => addr_virt_WR_FSMD_WRF,
				addr_py_RD1 => addr_py_RD1_FSMD_WRF,
				addr_py_RD2 => addr_py_RD2_FSMD_WRF,
				addr_py_WR => addr_py_WR_FSMD_WRF,
				fill_flag => fill_flag_WRF
			);
end architecture;


configuration CFG_ARCHSTRUCT_FSMD_WRF of FSMD_WRF is
	for ARCHSTRUCT
		for all : CU_FSM_WRF
			use configuration work.CFG_CU_FSM_WRF;
		end for;

		for all : DP_FSM_WRF
			use configuration work.CFG_DP_FSM_WRF;
		end for;
	end for;
end configuration;
