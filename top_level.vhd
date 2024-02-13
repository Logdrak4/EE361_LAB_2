library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

entity top_level is
		port (
		iClk					: in std_logic;
		--KEY INPUTS
      KEY0 					: in STD_LOGIC;
		KEY1					: in STD_LOGIC;
		KEY2					: in STD_LOGIC;
		KEY3					: in STD_LOGIC;
		--FOR TESTING
		disp_DATAOUT: buffer std_logic_vector(15 downto 0);
		--to SRAM CONNECTS	
		SRAM_IO : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);	
		SRAM_addr2SRAM: OUT STD_LOGIC_VECTOR(19 DOWNTO 0);
		SRAM_ce : OUT STD_LOGIC;
		SRAM_ub : OUT STD_LOGIC;
		SRAM_lb: OUT STD_LOGIC;
		SRAM_we : OUT STD_LOGIC;
		SRAM_oe : OUT STD_LOGIC;
		--to seven segment using IC2
		SDA : inout std_logic;
      SCL : inout std_logic;
		--to on board LCD
      LCD_EN      : out std_logic;
      LCD_RS      : out std_logic;
      LCD_DATA    : out std_logic_vector(7 downto 0);
		--should be tied to a value
		LCD_RW      : out std_logic:='0'; --low
      LCD_ON      : out std_logic:='1'; --high
      LCD_BACKLIGHT    : out std_logic:='0'; --high
		--PWM
		PWM_out : out std_logic
		);
end top_level;

architecture Structural of top_level is

	component Rom IS
		PORT
		(
			address		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
			clock			: IN STD_LOGIC  := '1';
			q				: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
		);
	END component;

	component univ_bin_counter is
		generic(N: integer := 8; N2: integer := 255; N1: integer := 0);
		port(
			clk, reset					: in std_logic;
			syn_clr, load, en, up	: in std_logic;
			clk_en 						: in std_logic := '1';			
			d								: in std_logic_vector(N-1 downto 0);
			max_tick, min_tick		: out std_logic;
			q								: out std_logic_vector(N-1 downto 0)		
		);
	end component;

	component clk_enabler is
		 GENERIC (
			 CONSTANT cnt_max : integer := 49999999);      --  1.0 Hz 	
		 PORT(	
			clock						: in std_logic;	 
			clk_en					: out std_logic
		);
	end component;
	

	component Reset_Delay IS	
		 PORT (
			  SIGNAL iCLK 		: IN std_logic;	
			  SIGNAL oRESET 	: OUT std_logic
				);	
	end component;	
	
	component btn_debounce_toggle is
		GENERIC(
			CONSTANT CNTR_MAX : std_logic_vector(15 downto 0) := X"FFFF");  
		Port( 
			BTN_I 	: in  STD_LOGIC;
         CLK 		: in  STD_LOGIC;
         BTN_O 	: out  STD_LOGIC;
         TOGGLE_O : out  STD_LOGIC;
		   PULSE_O  : out STD_LOGIC);
	end component;
	
	component State_Machine is 
		Port ( clk 			    : in STD_LOGIC; 
           clk_en 		    : in STD_LOGIC; 
           rst 				 : in STD_LOGIC; 
           keys  	 : in STD_LOGIC_VECTOR(3 downto 0); --change to button press
           --data_valid_pulse : in STD_LOGIC; 
           state 				 : out STD_LOGIC_VECTOR(2 downto 0);
			  counter : in STD_LOGIC_VECTOR(7 downto 0)
			  ); 
	end component; 
	
		component SRAM_Controller is
		
		port(
			clk: in std_logic;
			reset: in std_logic;
			pulse: in std_logic; --needed to initate a memory operation. tells the SRAM controller it is ready 
			R_W: in std_logic; --read =1 and write =0
			addr: in std_logic_vector(7 downto 0);
			DATAin: in std_logic_vector(15 downto 0);
			
			DATAout: out std_logic_vector(15 downto 0);
			ready: out std_logic;	
			IO: inout std_logic_vector(15 downto 0);	--IN and OUT between SRAM and SRAM controller
			Addr2SRAM: out std_logic_vector(19 downto 0); -- addr but padded with X"000"
			ceOUT: out std_logic;	--tie to '0' in top level
			ub: out std_logic;	--tie to '0' in top level
			lb: out std_logic;	--tie to '0' in top level
			weOUT: out std_logic;
			DoesWORK: out std_logic_vector(3 downto 0);
			oeOUT: out std_logic
		);
	end component;	
	
	component SystemModule is
    Port ( clk : in STD_LOGIC;        --clock_50
            state: in STD_LOGIC_VECTOR(3 downto 0);        --QState 4 bits
           -- Inputs if programming mode
           in_data_prog1 : in STD_LOGIC_VECTOR (3 downto 0);         --keypad data for data??
           in_data_prog2 : in STD_LOGIC_VECTOR (3 downto 0);         --keypad data for data??
           in_data_prog3 : in STD_LOGIC_VECTOR (3 downto 0);         --keypad data for data??
           in_data_prog4 : in STD_LOGIC_VECTOR (3 downto 0);        --keypad data for data??
           in_addr_prog1 : in STD_LOGIC_VECTOR (3 downto 0);        --keypad data for address??
           in_addr_prog2 : in STD_LOGIC_VECTOR (3 downto 0);        --Keypad data for address??
            -- inputs if operating mode. 
           in_data_oper1 : in STD_LOGIC_VECTOR (3 downto 0);        --SRAM(3 downto 0)
           in_data_oper2 : in STD_LOGIC_VECTOR (3 downto 0);        --SRAM(7 downto 4)
           in_data_oper3 : in STD_LOGIC_VECTOR (3 downto 0);        --SRAM(11 downto 8)
           in_data_oper4 : in STD_LOGIC_VECTOR (3 downto 0);        --SRAM(15 downto 12)
           in_addr_oper1 : in STD_LOGIC_VECTOR (3 downto 0);        -- counter first 4 digits
           in_addr_oper2 : in STD_LOGIC_VECTOR (3 downto 0);        -- counter second 4 digits
           -- Outputs for seven-segment displays
            display_out1 : out STD_LOGIC_VECTOR (6 downto 0);        --connect to first 7seg LED
            display_out2 : out STD_LOGIC_VECTOR (6 downto 0);         --connect to sec 7seg LED
            display_out3 : out STD_LOGIC_VECTOR (6 downto 0);         --connect to third 7seg LED
            display_out4 : out STD_LOGIC_VECTOR (6 downto 0);         --connect to four 7seg LED
            display_out5 : out STD_LOGIC_VECTOR (6 downto 0);         --connect to fifth 7seg LED
            display_out6 : out STD_LOGIC_VECTOR (6 downto 0)         --connect to sixth 7seg LED
);
end component;

component LCD_Protocol is
    generic( constant FREQ : integer:= 208335);
  Port (
  clk: in std_logic;     --system clock
  reset: in std_logic;      --reset signal
  InputData: in std_logic_vector(15 downto 0);
  addrIN: in std_logic_vector(7 downto 0);
  state: in std_logic_vector(2 downto 0);
  freq_STATE: in std_logic_vector(1 downto 0);
    Prev_state: out std_logic_vector(2 downto 0);
  oLCD_data : out std_logic_vector(7 downto 0);
  oLCD_en: out std_logic;
  oLCD_rs: out std_logic;
  oLCD_RW      : out std_logic:='0'; --low
  oLCD_ON      : out std_logic:='1'; --high
  oLCD_BACKLIGHT    : out std_logic:='1' --high
   );
end component;

component DDS is
    Port ( clk : in STD_LOGIC;
           reset: in STD_LOGIC;
			  state: in std_logic_vector(2 downto 0);
			  freq_state: in std_logic_vector(1 downto 0); --freq_select
			  addr: out std_logic_vector(7 downto 0) --addres going to SRAM
			  );
end component;

component PWM_Module is
    Port ( clk : in STD_LOGIC;
           reset: in STD_LOGIC;
			  freq_state: in std_logic_vector(1 downto 0); --freq_select
			  Data: in std_logic_vector(7 downto 0); 	--data in from sram/rom
			  PWM_pulse: out STD_LOGIC
			  );
end component;

component usr_logic is
port( clk : 	in std_logic;
		iData:   in std_logic_vector(15 downto 0); -- := X"abcd";

		oSDA: 	inout Std_logic;
		oSCL:		inout std_logic);

end component;

--component D_FF is
--PORT( D,CLOCK: in std_logic;
--		Q: out std_logic);
--end component;
 

	signal reset_d							: std_logic;
   signal Counter_Reset        		: std_logic;	
	signal clock_enable_60ns,clock_enable_60ns_D_FF,clock_enable_60ns_D_FF_2			: std_logic;
	signal clock_enable_1sec			: std_logic;
	signal KEY0_db,KEY1_db,KEY2_db,KEY3_db 						: std_logic;
	signal Qc								: std_logic_vector(7 downto 0); -- counter output
	signal Qr								: std_logic_vector(15 downto 0); -- Rom output
	signal mux_output_clken				: std_logic;
	signal mux_select_up					: std_logic_vector(1 downto 0);
	signal mux_output_up					: std_logic;
	signal mux_select_en					: std_logic;--: std_logic_vector(1 downto 0);
	signal mux_output_en					: std_logic;
	signal mux_select_clken				: std_logic_vector(1 downto 0);
	signal mux_select_pulse				: std_logic_vector(2 downto 0);
	signal mux_output_pulse				: std_logic;
	signal Qstate							: std_logic_vector(2 downto 0);
	signal OUTPUT_DATA_addrShift,OUTPUT_DATA_Datashift	: std_logic_vector(3 downto 0):= "0000";
	signal mux_select_RW					: std_logic;--: std_logic_vector(1 downto 0);
	signal mux_output_RW					: std_logic;
	signal sig_ceOUT, sig_ub, sig_lb: std_logic;
	signal mux_select_datain			: std_logic_vector(2 downto 0);
	signal mux_output_datain			: std_logic_vector(15 downto 0);
	signal NOT_KEY0_db 					: std_logic;
	signal AFTERSHIFT_DATA 				: std_LOGIC_VECTOR(15 downto 0);
	signal AFTERSHIFT_ADDR,mux_data_SRAM				: std_LOGIC_VECTOR(7 downto 0);
	signal AFTERSHIFT						: std_logic_vector(15 downto 0);
	signal clockEN5ms_sig,clockPulse5ms_sig,pulse_20ns_sig :  std_logic;
	signal OUTPUT_DATA : std_logic_vector(4 downto 0);
	signal clockEN5ms_sig_data,clockEN5ms_sig_addr: std_logic;
	signal mux_output_addrin,addr_from_DDS: std_logic_vector(7 downto 0);
	signal max_tick_sig: std_logic;
	signal SRAM_addr2SRAM_sig: std_logic_vector(19 downto 0);
	signal KeyMaster: std_lOGIC_VECTOR(3 downto 0);
	signal freq_select: std_logic_vector(1 downto 0);
	signal PWM_freq: std_logic;
	signal mux_output_I2C : std_logic_vector(15 downto 0);
	
	begin
	
	KeyMaster<= not KEY3_db &  not KEY2_db & not KEY1_db &  KEY0_db;  --maybe create from the debounced signals
					--"3210"
	SRAM_addr2SRAM<=SRAM_addr2SRAM_sig;
	
--	
	-- rw mux
	mux_select_RW <= Qstate(2);
	process(mux_select_RW,OUTPUT_DATA) 
	begin 
    case mux_select_RW is
        when '0' =>
            mux_output_RW <= '0'; --write
        when '1' =>
					mux_output_RW <= '1'; --reading
		  when others =>
            mux_output_RW <= '1'; --reading
    end case;
	end process;
--	
--	-- up mux
--	mux_select_up <= Qstate(3 downto 2); -- select based on state(3) and state(2)
--	process(mux_select_up, Qstate(1))
--	begin
--    case mux_select_up is
--        when "00" | "01" =>
--            mux_output_up <= Qstate(1);
--        when others =>
--            mux_output_up <= '0';
--    end case;
--	end process;
	
	-- en mux
	mux_select_en <= Qstate(1);
----	process(mux_select_en, Qstate(0))
----	begin
----    case mux_select_en is
----        when "00" | "01" =>
----            mux_output_en <= Qstate(0);
----        when others =>
----            mux_output_en <= '0';
----    end case;
----	end process;
	
	-- clock_en mux
	mux_select_clken <= Qstate(2 downto 1);
	process(mux_select_clken) 
	begin 
    case mux_select_clken is
        when "01" =>
            mux_output_clken <= clock_enable_60ns;		--initializing and PWM moode
				--mux_output_I2C <= X"0000"; --display zeros to I2C when not in test mode
        when "11" =>
            mux_output_clken <= clock_enable_1sec; 	--test mode
				--mux_output_I2C<=disp_DATAOUT;--display SSRAM data to I2C when in test mode
        when others =>
            mux_output_clken <= '0';
    end case;
	end process;
--	
	-- pulse mux not used until connected to SRAM
	mux_select_pulse <= Qstate(2 downto 0);
	process(mux_select_pulse)
	begin 
    case mux_select_pulse is
        when "011" =>
            mux_output_pulse <= clock_enable_60ns;  --initializing
				mux_output_I2C <= X"0000"; --display zeros to I2C when not in test mode

        when "110" =>
            mux_output_pulse <= clock_enable_1sec; --Test
				mux_output_I2C<=disp_DATAOUT;--display SSRAM data to I2C when in test mode
			when "111" =>
            mux_output_pulse <= '1'; --PWM
				mux_output_I2C <= X"0000"; --display zeros to I2C when not in test mode

        when others =>
            mux_output_pulse <= '0'; --pause
				mux_output_I2C<=disp_DATAOUT;--display SSRAM data to I2C when in test mode
    end case;
	end process;
	
	-- reading to SRAM from rom or keypad
	mux_select_datain <= Qstate(2 downto 0);
	process(mux_select_datain) 
	begin 
    case mux_select_datain is
        when "111" =>		--PWM generation
				mux_output_addrin <=addr_from_DDS;	
            --mux_output_datain <= AFTERSHIFT_DATA;
		   when others =>		--Initializing, test, etc.
				mux_output_addrin <=Qc;
            mux_output_datain <= Qr;
			
    end case;
	end process;
	
	--ADD MUX TO DECIDE WHEN TO SEND sram TO THE SEVEN SEGMENT DISPLAY. ONLY IN TEST MODE
	
 Counter_Reset <= reset_d; --or max_tick_sig; -- or  not KEY0_db NEED TO RESET after intialization

 
 			sig_ceOUT <='0';
			sig_lb <='0';
			sig_ub <='0';
			SRAM_lb<=sig_lb;
			SRAM_ub<=sig_ub;
			SRAM_ce<=sig_ceOUT;
			
	Inst_clk_Reset_Delay: Reset_Delay	
			port map(
			  iCLK 		=> iClk,	
			  oRESET    => reset_d
			);			
--	Inst_D_FF: D_FF 
--	PORT MAP( D => clock_enable_60ns,
--				CLOCK =>iClk,
--				Q=> clock_enable_60ns_D_FF
--				);

	Inst_clk_enabler1sec: clk_enabler
			generic map(
			cnt_max 		=> 49999999)
			port map( 
			clock 		=> iClk, 			--  from system clock
			clk_en 		=> clock_enable_1sec  
			);
			
	Inst_clk_enabler60ns: clk_enabler
			generic map(
			cnt_max 		=> 2) -- 833333 or 3000
			port map( 
			clock 		=> iClk, 			
			clk_en 		=> clock_enable_60ns  
			);	
			
	Inst_univ_bin_counter: univ_bin_counter
		generic map(N => 8, N2 => 255, N1 => 0)
		port map(
			clk 			=> iClk,
			reset 		=> Counter_Reset,
			syn_clr		=>  '0', 
			load			=> '0', 
			en				=> mux_select_en, --pause or stop
			up				=> '1', --up
			clk_en 		=> mux_output_clken, --mux_select_clken
			d				=> (others => '0'),
			max_tick		=> open, 
			min_tick 	=> open,
			q				=> Qc 
		);

	inst_KEY0: btn_debounce_toggle
		GENERIC MAP( CNTR_MAX => X"FFFF") -- use X"FFFF" for implementation
		Port Map(
			BTN_I => KEY0,
			CLK => iClk,
			BTN_O => KEY0_db,
			TOGGLE_O => open,
			PULSE_O => open);
	inst_KEY1: btn_debounce_toggle
		GENERIC MAP( CNTR_MAX => X"FFFF") -- use X"FFFF" for implementation
		Port Map(
			BTN_I => KEY1,
			CLK => iClk,
			BTN_O => open,
			TOGGLE_O => open,
			PULSE_O => KEY1_db);
	inst_KEY2: btn_debounce_toggle
		GENERIC MAP( CNTR_MAX => X"FFFF") -- use X"FFFF" for implementation
		Port Map(
			BTN_I => KEY2,
			CLK => iClk,
			BTN_O => open,
			TOGGLE_O => open,
			PULSE_O => KEY2_db);
	inst_KEY3: btn_debounce_toggle
		GENERIC MAP( CNTR_MAX => X"FFFF") -- use X"FFFF" for implementation
		Port Map(
			BTN_I => KEY3,
			CLK => iClk,
			BTN_O => open,
			TOGGLE_O => open,
			PULSE_O => KEY3_db);			
		
	Inst_Rom: Rom
		Port Map(
			address => Qc,
			clock => iClk,
			q =>  Qr -- Qr when finished testing
		);
		
	Inst_State_Machine: State_Machine
		port map(
			 clk 			=> iClk,
          clk_en 		=> '1',
          rst 			=> Counter_Reset,
          keys  => KeyMaster,
          --data_valid_pulse => clockEN5ms_sig,
          state => Qstate,
			 counter => Qc	 
			);

Inst_SRAM_Controller: SRAM_Controller
		
		port map(
			clk => iClk,
			reset => Counter_Reset,
			pulse => mux_output_pulse,		--????
			R_W => mux_output_RW, 			--hardwire to a switch, '1' for reading and '0' for writing
			addr => mux_output_addrin,      --mux_output_addrin,		--hardwire using switches in binary 0x00001
			DATAin => Qr,    --mux_output_datain,	--hardwire using switches in binary 0x0003
			
			DATAout=> disp_DATAOUT, 
			
			ready => open, --goes to SRAM?	
			IO => SRAM_IO, --IN and OUT between SRAM and SRAM controller
			Addr2SRAM => SRAM_addr2SRAM_sig,-- GOES TO SRAM addr but padded with X"000"
			ceOUT => open, 	-- GOES to SRAM BUT SHOULD BE TIED TO 0
			ub => open,		-- GOES to SRAM BUT SHOULD BE TIED TO 0
			lb => open,		-- GOES to SRAM BUT SHOULD BE TIED TO 0
			weOUT => SRAM_we,
			DoesWORK=> open,
			oeOUT => SRAM_oe
		);
		
--		process(OUTPUT_DATA)
--		begin 
--				if (OUTPUT_DATA(4) = '0') then
--					if (Qstate(3 downto 1) = "101") then
--						OUTPUT_DATA_Datashift <=OUTPUT_DATA(3 downto 0);
--						clockEN5ms_sig_data<=clockEN5ms_sig;
--					end if;
--				if(Qstate(3 downto 1) = "100") then
--						OUTPUT_DATA_addrShift <=OUTPUT_DATA(3 downto 0);
--						clockEN5ms_sig_addr<=clockEN5ms_sig;
--					end if;
--				end if;
--		end process;
--	 



	--DETERMINE PWM freq state
	 select_PWM_FREQ_STATE: process(iClk, Qstate)
	 begin	
			if rising_edge(iClk) then
				if Qstate = "111" then
				case freq_select is
				when "00" => --60 Mhz
					mux_data_SRAM<=disp_DATAOUT(15 downto 8);
					if keyMaster(3)='0' then
						freq_select <= "01"; -- to 120 Mhz
					end if;
				when "01" => --120 Mhz
					mux_data_SRAM<=disp_DATAOUT(15 downto 8);
					if keyMaster(3)='0' then
						freq_select <= "10"; -- to 1000 Mhz
					end if;
				when "10" => --1000 Mhz
					mux_data_SRAM<="00"&disp_DATAOUT(15 downto 10);
					if keyMaster(3)='0' then
						freq_select <= "00"; -- to 60 Mhz
					end if;
				when others =>
					freq_select <= "00"; --60 Mhz
			end case;
				else 
				freq_select<="00";
			end if;
			end if;
		end process;
--		
--		select_FREQ_FROM_STATE: process(freq_select)
--		begin
--		with freq_select select
--			PWM_freq <= --60Mhz signal when "00"
--							--120Mhz signal when "01"
--							--1000Mhz signal when "10"
--							--60Mhz signal when others
--		end process;
--				
	--PROBABLY DONT NEED
--	INST_7seg: SystemModule
--    Port map ( clk =>iCLK,
--            state => Qstate,
--           -- Inputs if programming mode
--           in_data_prog1=> AFTERSHIFT_DATA(3 downto 0),        --keypad data for data?? ones with a '0' in front
--           in_data_prog2=> AFTERSHIFT_DATA(7 downto 4),              --keypad data for data??
--           in_data_prog3=> AFTERSHIFT_DATA(11 downto 8),             --keypad data for data??
--           in_data_prog4=> AFTERSHIFT_DATA(15 downto 12),             --keypad data for data??
--           in_addr_prog1=> AFTERSHIFT_ADDR(3 downto 0),       --keypad data for address??
--           in_addr_prog2=> AFTERSHIFT_ADDR(7 downto 4),      --Keypad data for address??
--            -- inputs if operating mode. 
--           in_data_oper1 => disp_DATAOUT(3 downto 0),       --SRAM(3 downto 0)
--           in_data_oper2  => disp_DATAOUT(7 downto 4),        --SRAM(7 downto 4)
--           in_data_oper3 => disp_DATAOUT(11 downto 8),       --SRAM(11 downto 8)
--           in_data_oper4  => disp_DATAOUT(15 downto 12),        --SRAM(15 downto 12)
--           in_addr_oper1  => SRAM_addr2SRAM_sig(3 downto 0),         -- counter first 4 digits
--           in_addr_oper2  => SRAM_addr2SRAM_sig(7 downto 4),        -- counter second 4 digits
--           -- Outputs for seven-segment displays
--            display_out1 =>Hex0_sig,        --connect to first 7seg LED
--            display_out2 =>Hex1_sig,        --connect to sec 7seg LED
--            display_out3 =>Hex2_sig,        --connect to third 7seg LED
--            display_out4 =>Hex3_sig,        --connect to four 7seg LED
--            display_out5 =>Hex4_sig,        --connect to fifth 7seg LED
--            display_out6 =>Hex5_sig         --connect to sixth 7seg LED
--	);

Inst_LCD_Protocol: LCD_Protocol 
    generic map(  FREQ => 208335)
  Port map(
  clk =>iCLK,
  reset => reset_d,      --reset signal
  InputData=> disp_DATAOUT, --data to display out
  addrIN=>SRAM_addr2SRAM_sig(7 downto 0),
  state => Qstate,
  freq_STATE=>freq_select,
  prev_state=> open,
  oLCD_data=>LCD_DATA,
  oLCD_en=> LCD_EN,
  oLCD_rs=> LCD_RS,
  oLCD_RW=> LCD_RW,
  oLCD_ON=> LCD_ON,
  oLCD_BACKLIGHT=> LCD_BACKLIGHT
   );
	
	Inst_DDS: DDS
    Port map( clk =>iCLK,
           reset =>reset_d,
			  state => Qstate,
			  freq_state=>freq_select,
			  addr=>addr_from_DDS --to mux to sram to choose which data to output
			  );
			  
Inst_PWM_Module: PWM_Module
    Port map ( clk=>iCLK,
           reset=>reset_d,
			  freq_state=>freq_select,	--freq_select to show state of freqency
			  Data=>mux_data_SRAM,	--data in from sram/rom truncated to 8 bits
			  PWM_pulse=>PWM_out --to port
			  );

Inst_usr_logic : usr_logic
port map( clk=>iCLK,
		iData=> mux_output_I2C,
		oSDA=>SDA,
		oSCL=>SCL
);

	 
end Structural;
