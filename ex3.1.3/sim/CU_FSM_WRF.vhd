library ieee;
use ieee.std_logic_1164.all;
use work.constants.all;

entity CU_FSM_WRF is
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
end entity;

architecture beh of CU_FSM_WRF is
-- states definition
type state_type is (s_start, idle, op_reg1, op_reg2, call_free, call_spill_1, call_spill_2, restore_y1, restore_y2, restore_n1, restore_fill_1, restore_fill_2, restore_fill_3);				
signal currState, nextState : state_type;	-- signals for current state of the Control FSM

begin

	StateReg : process(Clk)	-- state register
	begin
		if (rising_edge(Clk)) then
			if (Rst_CU_FSM_WRF = '1') then
				currState <= s_start;		-- start state if reset everything
			else
				currState <= nextState;	
			end if;
		end if;
	end process;

	CombLogic : process (currState, RD1_CU_FSM_WRF_in, RD2_CU_FSM_WRF_in, WR_CU_FSM_WRF_in, call_ctrl, return_ctrl, TC_upcnt, free, can_return, start_seq, ack)
	begin
		-- by default all the outputs are setled to 0
		RD1_CU_FSM_WRF_out <= '0';
		RD2_CU_FSM_WRF_out <= '0';
		WR_CU_FSM_WRF_out <= '0';
		en_rst_rom <= '0';
		load_reg_cwp <= '0';
		load_reg_swp <= '0';
		load_reg_cansave <= '0';
		load_reg_canreturn <= '0';
		en_lut_rom <= '1';
		rst_upcnt <= '0';
		cnt_upcnt <= '0';
		rotL_CWP <= '0';
		rotR_CWP <= '0';
		rotL_SWP <= '0';
		rotR_SWP <= '0';
		cansave_update_and <= '0';
		cansave_update_or <= '0';
		canreturn_update_and <= '0';
		canreturn_update_or <= '0'; 
		spill_fill_flg <= '0';
		addr_virt_sel_port1 <= '0';
		fill_flag <= '0';





		
		case currState is

			when s_start =>
			-- initial state where we reset CWP, SWP, CANSAVE, CANRETURN 
			-- reset CWP, SWP, CANSAVE, CANRETURN
			en_rst_rom <= '1'; 
			load_reg_cwp <= '1';
			load_reg_swp <= '1';
			load_reg_cansave <= '1';
			load_reg_canreturn <= '1';
			-- next state is the IDLE one
			nextState <= idle;
			
			when idle =>
			-- idle state waiting for any request (R/W, call, return)
			rst_upcnt <= '1'; -- reset counter status (zeroed-out)
			if (En_CU_FSM_WRF = '1' and (RD1_CU_FSM_WRF_in = '1' or RD2_CU_FSM_WRF_in = '1' or WR_CU_FSM_WRF_in = '1')) then
				-- a read/write request has been received and the enable is active
				-- therefore the next state is op_reg
				nextState <= op_reg1;
			elsif (call_ctrl = '1' and free = '1') then
				-- next state is call_free since call signal has heen raised and free signal is high
				nextState <= call_free;
			elsif (call_ctrl = '1' and free = '0') then
				-- spill needed
				nextState <= call_spill_1;
			elsif (return_ctrl = '1' and can_return = '0') then
				-- fill needed
				nextState <= restore_n1;
			elsif (return_ctrl = '1' and can_return = '1') then
				-- no fill needed
				nextState <= restore_y1;
			else
				nextState <= idle; -- stay in idle state
			end if;

			when op_reg1 =>
			-- state in which a normal R/W operation in done within the current window

			-- en_lut_rom <= '1';  -- translation from virtual to physical address
			addr_virt_sel_port1 <= WR_CU_FSM_WRF_in;  -- select write or read addr on port 1
			nextState <= op_reg2;

			when op_reg2 =>
			RD1_CU_FSM_WRF_out <= RD1_CU_FSM_WRF_in;    -- drive control input signal as output
			RD2_CU_FSM_WRF_out <= RD2_CU_FSM_WRF_in;    -- therefore they must stay stable and high
			WR_CU_FSM_WRF_out <= WR_CU_FSM_WRF_in;		-- and not active one clock cycle only

			--if (En_CU_FSM_WRF = '0' or (RD1_CU_FSM_WRF_in = '0' and RD2_CU_FSM_WRF_in = '0' and WR_CU_FSM_WRF_in = '0')) then
				-- no read/write signal anymore or enable not still active therefore coming back to idle state
				nextState <= idle;
			--else
			--	nextState <= op_reg1;
			--end if;
			
			when call_free =>
			-- the call can be satisfied
			rotR_CWP <= '1';  -- move current window pointer to the next window
			cansave_update_and <= '1';  -- mark the previous window as not free anymore
			nextState <= idle; -- once pointer and flag update coming back to idle state waiting for new requests

			when call_spill_1 =>
			-- call requires a spill 
			cnt_upcnt <= '1';  -- counting up by 1
			spill_fill_flg <= '1';  -- generating addresses for spill from the counter
			en_lut_rom <= '1';
			RD2_CU_FSM_WRF_out <= '1'; -- reading on port #2 of the register file
			if (TC_upcnt = '1') then
				nextState <= call_spill_2; -- addresses generation finished, moving to the state that updates pointer and flags
			else
				nextState <= call_spill_1;  -- stay in the current state
			end if;

			when call_spill_2 =>
			-- spill operation done, updating CANRESTORE, CANSAVE, CWP, SWP
			rotR_SWP <= '1';  -- updating pointer for CWP and SWP
			rotR_CWP <= '1';
			cansave_update_and <= '1';  -- updating cansave... Previous window not free anymore
			canreturn_update_and <= '1';  -- mark that the previous window has been spilled
			nextState <= idle;  -- spill finished, coming back to idle state
			
			when restore_y1 =>
			-- restore possible, no fill from memory needed
			rotL_CWP <= '1';
			nextState <= restore_y2;
			
			when restore_y2 =>
			-- second state for restore without fill from the memory
			cansave_update_or <= '1';
			nextState <= idle;  -- return done, coming back to idle state

			when restore_n1 =>
			-- restore requires a fill that is managed as follow: the main memory sends one register at a time in the proper
			-- order, with start signal high when the first register is sent and ack high when the last one is sent
			rotL_SWP <= '1'; -- moving back saved window pointer
			nextState <= restore_fill_1;

			when restore_fill_1 =>
			rst_upcnt <= '1';  -- zeroed-out counter in order to be ready for counting up
			en_lut_rom <= '1';	
			fill_flag <= '1'; -- driving fill address generation on addr1 of the register file
			if (start_seq = '1') then
				nextState <= restore_fill_2;
			else
				nextState <= restore_fill_1;  -- stay in the current state
			end if;

			when restore_fill_2 =>
			-- starting fill... we suppose that each clock cycle we receive a new register
			fill_flag <= '1'; -- driving fill address generation on addr1 of the register file
			cnt_upcnt <= '1';  -- starting counting up for automatic address generation for fill operation
			WR_CU_FSM_WRF_out <= '1'; -- writing on register file
			spill_fill_flg <= '1'; -- driving the automatic address generated in input to port 2		
			if (ack = '1') then
				nextState <= restore_fill_3;
			else
				nextState <= restore_fill_2;
			end if;

			when restore_fill_3 =>
			canreturn_update_or <= '1';  -- update flag after fill operation
			nextState <= restore_y1;  -- now is possible to return after fill
		
			when others =>
				nextState <= s_start; -- safe FSM comes back to the reset state

		end case;
	end process;
end architecture;

configuration CFG_CU_FSM_WRF of CU_FSM_WRF is
	for beh
	end for;
end configuration;
