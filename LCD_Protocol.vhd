
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--library UNISIM;
--use UNISIM.VComponents.all;

entity LCD_Protocol is
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
  oLCD_BACKLIGHT    : out std_logic:='0' --high
   );
end LCD_Protocol;

architecture Behavioral of LCD_Protocol is
    --Create state machine to send out preperation data and then repeating data
	component HexToASCII is
    Port ( hex_digit : in STD_LOGIC_VECTOR (3 downto 0);
           ascii : out STD_LOGIC_VECTOR (7 downto 0));
	end component;

    signal registerSel   : integer range 0 to 29:=0;
	 signal registerSel_PWM: integer range 0 to 20:=0;
	 signal registerSel_Test   : integer range 0 to 26:=0;
	 signal registerSel_INIT: integer range 0 to 21:=0;
	 signal registerSel_Pause:integer range 0 to 27:=0;
	 signal LUT_MAX,LUT_repeat		: integer range 0 to 29:=0;
    signal cnt      : integer range 0 to FREQ; ----TODO: Use CntMax in implementation
    signal LCD_cnt      : integer range 0 to FREQ; ----TODO: Use CntMax in implementation
	signal clock_en : std_logic;
	signal LCD_en:  std_logic;
	signal LCD_EN_SIG : std_logic:='0';
	signal LCD_RS_SIG : std_logic:='0';
	signal BackToZero : integer range 0 to 2:=0;
    type asciiArray is array(0 to 6) of std_logic_vector(7 downto 0);
    signal ascii : asciiArray;
    type HexArray is array(0 to 3) of std_logic_vector(3 downto 0);
    signal HEX_digit : HexArray;
    signal digit: integer range 0 to 3;
	 signal allData,allData_Test,allData_INIT,alldata_Pause :STD_LOGIC_VECTOR (8 downto 0);
	 signal previous_state: std_logic_vector(2 downto 0);
	 signal freq_prev: std_logic_vector(1 downto 0);

    
begin

--    HEX_digit(3) <= InputData(3 downto 0);
--    HEX_digit(2) <= InputData(7 downto 4);
--    HEX_digit(1) <= InputData(11 downto 8);
--    HEX_digit(0) <= InputData(15 downto 12);
	 
	 --test
--	 HEX_digit(0) <= X"F";
--    HEX_digit(1) <= X"0";
--    HEX_digit(2) <= X"0";
--    HEX_digit(3) <= X"D";

    INST_hextoascii0: HexToASCII Port map( hex_digit=>InputData(3 downto 0), ascii=>ascii(0));
	 INST_hextoascii1: HexToASCII Port map( hex_digit=>InputData(7 downto 4), ascii=>ascii(1));
	 INST_hextoascii2: HexToASCII Port map( hex_digit=>InputData(11 downto 8), ascii=>ascii(2));
	 INST_hextoascii3: HexToASCII Port map( hex_digit=>InputData(15 downto 12), ascii=>ascii(3));
	 INST_hextoascii4: HexToASCII Port map( hex_digit=>addrIN(3 downto 0), ascii=>ascii(4));
	 INST_hextoascii5: HexToASCII Port map( hex_digit=>addrIN(7 downto 4), ascii=>ascii(5));
	Test_State: process(registerSel_Test)
	begin
	case registerSel_Test is
       when 0  => allData_Test <= "0"&X"38";
       when 1  => allData_Test <= "0"&X"38";
       when 2  => allData_Test <= "0"&X"38";	   
       when 3  => allData_Test <= "0"&X"38";
       when 4  => allData_Test <= "0"&X"38";
       when 5  => allData_Test <= "0"&X"38";
       when 6  => allData_Test <= "0"&X"01";
       when 7  => allData_Test <= "0"&X"0C";
       when 8  => allData_Test <= "0"&X"06";	   
       when 9  => allData_Test <= "0"&X"80";
		 
       when 10 => allData_Test <= "1"&X"54"; --T
       when 11 => allData_Test <= "1"&X"65"; --e
       when 12 => allData_Test <= "1"&X"73"; --s
       when 13 => allData_Test <= "1"&X"74"; --t
		 
       when 14 => allData_Test <= "1"&X"20"; --space
		 
       when 15 => allData_Test <= "1"&X"4D"; --M
       when 16 => allData_Test <= "1"&X"6F"; --o	
       when 17 => allData_Test <= "1"&X"64"; --d
       when 18 => allData_Test <= "1"&X"65"; --e
		 
		 --when 19 => allData_Test <= "0"&X"79";
       when 19 => allData_Test <= "0"&X"C0"; --new line --repeat here
		 
       when 20 => allData_Test <= "1"&ascii(5); --address first bit
       when 21 => allData_Test <= "1"&ascii(4); --address second bit	
		 

       when 22 => allData_Test <= "1"&X"20"; --should repeat starting here
		
       when 23 => allData_Test <= "1"&ascii(3); --ascii(0); --Inputdata should be inputted here from the ascii first character
       when 24 => allData_Test <= "1"&ascii(2); --ascii(1);  --second ascii character
       when 25 => allData_Test <= "1"&ascii(1); --ascii(2);  --third ascii character
       when 26 => allData_Test <= "1"&ascii(0); --ascii(3);  --fourth ascii character
   end case;
end process;
Pause_State: process(registerSel_Pause)
	begin
	case registerSel_Pause is
       when 0  => allData_pause <= "0"&X"38";
       when 1  => allData_pause <= "0"&X"38";
       when 2  => allData_pause <= "0"&X"38";	   
       when 3  => allData_pause <= "0"&X"38";
       when 4  => allData_pause <= "0"&X"38";
       when 5  => allData_pause <= "0"&X"38";
       when 6  => allData_pause <= "0"&X"01";
       when 7  => allData_pause <= "0"&X"0C";
       when 8  => allData_pause <= "0"&X"06";	   
       when 9  => allData_pause <= "0"&X"80";
		 
       when 10 => allData_pause <= "1"&X"50"; --P
       when 11 => allData_pause <= "1"&X"61"; --a
       when 12 => allData_pause <= "1"&X"75"; --u
       when 13 => allData_pause <= "1"&X"73"; --s
		 when 14 => allData_pause <= "1"&X"65"; --e
	
       when 15 => allData_pause <= "1"&X"20"; --space
		 
       when 16 => allData_pause <= "1"&X"4D"; --M
       when 17 => allData_pause <= "1"&X"6F"; --o	
       when 18 => allData_pause <= "1"&X"64"; --d
       when 19 => allData_pause <= "1"&X"65"; --e
		 
		 --when 19 => allData_Test <= "0"&X"79";
       when 20 => allData_pause <= "0"&X"C0"; --new line --repeat here
		 
       when 21 => allData_pause <= "1"&ascii(5); --address first bit
       when 22 => allData_pause <= "1"&ascii(4); --address second bit	
		

       when 23 => allData_pause <= "1"&X"20"; --should repeat starting here
		
       when 24 => allData_pause <= "1"&ascii(3); --ascii(3); --Inputdata should be inputted here from the ascii first character
       when 25 => allData_pause <= "1"&ascii(2); --ascii(2);  --second ascii character
       when 26 => allData_pause <= "1"&ascii(1); --ascii(1);  --third ascii character
       when 27 => allData_pause <= "1"&ascii(0); --ascii(0);  --fourth ascii character
   end case;
end process;

   INIT_State: process(registerSel_INIT)
	begin
	case registerSel_INIT is
       when 0  => allData_INIT <= "0"&X"38";
       when 1  => allData_INIT <= "0"&X"38";
       when 2  => allData_INIT <= "0"&X"38";	   
       when 3  => allData_INIT <= "0"&X"38";
       when 4  => allData_INIT <= "0"&X"38";
       when 5  => allData_INIT <= "0"&X"38";
       when 6  => allData_INIT <= "0"&X"01";
       when 7  => allData_INIT <= "0"&X"0C";
       when 8  => allData_INIT <= "0"&X"06";	   
       when 9  => allData_INIT <= "0"&X"80";
		 
       when 10 => allData_INIT <= "1"&X"49"; --I
       when 11 => allData_INIT <= "1"&X"6E"; --n
       when 12 => allData_INIT <= "1"&X"69"; --i
       when 13 => allData_INIT <= "1"&X"74"; --t
       when 14 => allData_INIT <= "1"&X"69"; --i
       when 15 => allData_INIT <= "1"&X"61"; --a	
       when 16 => allData_INIT <= "1"&X"6C"; --l
       when 17 => allData_INIT <= "1"&X"69"; --i
		 when 18 => allData_INIT <= "1"&X"7A"; --z
		 when 19 => allData_INIT <= "1"&X"69"; --i
		 when 20 => allData_INIT <= "1"&X"6E"; --n
		 when 21 => allData_INIT <= "1"&X"67"; --g
		 --when others =>allData_INIT <= "1"&X"67";

   end case;
end process;
 REGISTERSELECT: process(registerSel_PWM)
    begin
    case registerSel_PWM is
       when 0  => allData <= "0"&X"38";
       when 1  => allData <= "0"&X"38";
       when 2  => allData <= "0"&X"38";	   
       when 3  => allData <= "0"&X"38";
       when 4  => allData <= "0"&X"38";
       when 5  => allData <= "0"&X"38";
       when 6  => allData <= "0"&X"01";
       when 7  => allData <= "0"&X"0C";
       when 8  => allData <= "0"&X"06";	   
       when 9  => allData <= "0"&X"80";
       when 10 => allData <= "1"&X"50"; --P
       when 11 => allData <= "1"&X"57"; --W
       when 12 => allData <= "1"&X"4D"; --M
		 
--       when 13 => allData <= "1"&X"74"; --t
--       when 14 => allData <= "1"&X"65"; --e
--       when 15 => allData <= "1"&X"6D"; --m
--       when 16 => allData <= "1"&X"FE"; --R
--       when 17 => allData <= "1"&X"52"; --e
--       when 18 => allData <= "1"&X"65"; --a
--       when 19 => allData <= "1"&X"61"; --d
--       when 20 => allData <= "1"&X"64"; --y
--       when 21 => allData <= "0"&X"79"; --	

       when 13 => allData <= "0"&X"C0"; --should repeat starting here
		 
       when 14 => 
			if(freq_STATE= "00") then --60 MHZ
				allData <= "1"&X"36"; -- 6
			else --120 MHZ or 1000 Mhz
				allData <= "1"&X"31"; -- 1
			end if;
       when 15 => 
		 	if (freq_STATE = "00") then --60 MHZ 0r 1000 MHZ
				allData <= "1"&X"30"; -- 0
			elsif (freq_STATE = "10") then 
				allData <= "1"&X"30"; -- 0
			else 							--120 MHZ or 1000 Mhz
				allData <= "1"&X"32"; -- 2
			end if;
       when 16 => 
		   if(freq_STATE= "00") then --60 MHZ
				allData <= "1"&X"20"; -- space
			elsif (freq_STATE = "01") then
				allData <= "1"&X"30"; -- 0
			elsif (freq_STATE = "10") then --120 MHZ or 1000 Mhz
				allData <= "1"&X"30"; -- 0
			end if;
       when 17 => 
		 	if(freq_STATE= "00") then --60 HZ
				allData <= "1"&X"48"; -- H
			elsif (freq_STATE= "01") then --120 HZ
				allData <= "1"&X"20"; -- space
			elsif (freq_STATE= "10") then --1000 HZ
				allData <= "1"&X"30"; -- 0
			end if;
       when 18 =>
		 	if(freq_STATE= "00")then --60 HZ
				allData <= "1"&X"7A"; -- z
			elsif (freq_STATE= "01")then --120 HZ
				allData <= "1"&X"48"; -- H
			elsif (freq_STATE= "10")then --1000 HZ
				allData <= "1"&X"20"; -- space
			end if;
       when 19 =>
		 	if(freq_STATE= "00")then --60 HZ
				allData <= "1"&X"20"; -- ""
			elsif (freq_STATE= "01")then --120 HZ
				allData <= "1"&X"7A"; -- z
			elsif (freq_STATE= "10")then --1000 HZ
				allData <= "1"&X"48"; -- H
			end if;
       when 20 => 
			if(freq_STATE= "00")then --60 HZ
				allData <= "1"&X"20"; -- ""
			elsif (freq_STATE= "01")then --120 HZ
				allData <= "1"&X"20"; -- ""
			elsif (freq_STATE= "10")then --1000 HZ
				allData <= "1"&X"7A"; -- z
			end if;

   end case;
end process;

Clock_Enable: process(clk, reset)
begin
  if reset = '1' then 
	    cnt<=1;
	    clock_en<='0';
	    LCD_en <= '0';
	    LCD_cnt<=1;
	    BackToZero<=0;
  elsif rising_edge(clk) then
  
	if cnt = FREQ then      
		  clock_en <= '1';
		  cnt <=1;
	else
		  clock_en <= '0';
		  cnt <= cnt+1;
	end if;
	if LCD_cnt = ((FREQ/3)) then      
		  LCD_en <= '1';
		  LCD_cnt <=1;
		   if BackToZero=2 then
	       BackToZero<=0;
	       elsif BackToZero<2 then
	       BackToZero<=BackToZero+1;
	       end if;
		  
	else
		  LCD_en <= '0';
		  LCD_cnt <= LCD_cnt+1;
	end if;
end if;
end process;
--TEST to try and figure out LED_EN

LCD_Enabler: process(clk,clock_en, reset,LCD_RS_SIG,registerSel,LCD_en,BackToZero)
begin

  if reset = '1' then 
	    LCD_EN_SIG<='0';
	    oLCD_en<=LCD_EN_SIG;
    elsif (LCD_en='1'and(clock_en='0')) then
          if (BackToZero=1) then
	       LCD_EN_SIG <= '1';
	       oLCD_en<= not LCD_EN_SIG;
	       elsif BackToZero=0 then 
	       LCD_EN_SIG <= '0';
	       oLCD_en<= not LCD_EN_SIG;
	       elsif BackToZero =2 then
	       LCD_EN_SIG <= '0';
	       oLCD_en<=LCD_EN_SIG;
	       end if;
    else 
	       LCD_EN_SIG <=LCD_EN_SIG ;
	       oLCD_en<=LCD_EN_SIG;
	end if;
end process;


     LOGIC: process (clk,clock_en,reset) --,state
     begin
					case state is
					when "110" =>
						LUT_MAX<=26;
						LUT_repeat<=19;
						oLCD_data<=alldata_Test(7 downto 0);
						oLCD_rs<=alldata_Test(8);
					when "011" =>
						LUT_MAX<=21;
						LUT_repeat<=9;
						oLCD_data<=alldata_INIT(7 downto 0);
						oLCD_rs<=alldata_INIT(8);
					when "101" =>
						LUT_MAX<=27;
						LUT_repeat<=20;
						oLCD_data<=alldata_Pause(7 downto 0);
						oLCD_rs<=alldata_Pause(8);
					when "111" =>
						LUT_MAX<=20;
						LUT_repeat<=13;
						oLCD_data<=alldata(7 downto 0);
						oLCD_rs<=alldata(8);
					when others =>
						LUT_MAX<=10;
						LUT_repeat<=9;
					end case;
            if(reset='1' or state /= previous_state or freq_STATE /= freq_prev) then
                registerSel<=0;
					 oLCD_data<=X"31";
                oLCD_rs<='0';               
              elsif(rising_edge(clk) and clock_en='1') then
						if registerSel < LUT_MAX then
							registerSel <= registerSel + 1;
--           	        if registerSel<9 or registerSel=21 then
--           	        LCD_RS_SIG<='0';
--           	        --oLCD_rs<='0'; 
--           	        else
--           	        LCD_RS_SIG<='1';
--           	        --oLCD_rs<='1'; 
--           	        end if
								if state = "110" then
									registerSel_Test<=registerSel;
								elsif state = "011" then
									registerSel_INIT<=registerSel;
								elsif state = "101" then
									registerSel_Pause<=registerSel;
								elsif state= "111" then
									registerSel_PWM<=registerSel;
								end if;
						else	 
								registerSel<= LUT_repeat; 	
								if state = "110" then
									registerSel_Test<=registerSel;
								elsif state = "011" then
									registerSel_INIT<=registerSel;
								elsif state = "101" then
									registerSel_Pause<=registerSel;
								elsif state= "111" then
									registerSel_PWM<=registerSel;
								end if;     
         	      end if;

   	         end if;
        end process LOGIC;
		   process(clk, reset)
			begin
			if reset = '1' then
				previous_state <= (others => '0');
				freq_prev<= (others => '0');
			elsif rising_edge(clk) then
				previous_state <= state;
				freq_prev<= freq_STATE;
			end if;
			end process;

		  oLCD_BACKLIGHT<='1';
		  oLCD_ON<='1';
		  oLCD_RW<='0';
end Behavioral;
