library ieee;
use ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
entity SevenSeg_Controller is
	generic(
		sevenseg_addr : std_logic_vector(6 downto 0) := "1110001" -- seven segment display address
	);
	port (
---------------------------------------------------------------------------------------------------------
-- Project
		dataIn : in std_logic_vector(15 downto 0); -- 4 hexadecimal digits to display to seven segment
		clk	: in	std_logic;	-- clock
		--reset	: in	std_logic;	-- reset
---------------------------------------------------------------------------------------------------------
-- I2C
		sda	: inout  std_logic;	-- serial data output of I2C bus
		scl	: inout  std_logic	-- serial clock output of I2C bus
);
end SevenSeg_Controller;

architecture Behavioral of SevenSeg_Controller is
---------------------------------------------------------------------------------------------------------
-- Signals
type state_type is(start, ready, data_valid, busy_high, repeat, write2LED, stop);
signal state : state_type:=start;
signal data : std_logic_vector(7 downto 0);
signal i2c_data : std_logic_vector(7 downto 0);
signal i2c_en: std_logic:='0';
signal reset_n, i2c_err, i2c_busy : std_logic;
signal busy, busy_prev, busy_fall : std_logic;
signal sda_sig, scl_sig : std_logic;
signal byteSel : integer range 0 to 12:=0;
signal counter : unsigned(19 downto 0) := X"03FFF";
signal next_data: std_logic_vector(15 downto 0);

component i2c_master IS
  GENERIC(
    input_clk : INTEGER := 100_000_000; --input clock speed from user logic in Hz
    bus_clk   : INTEGER := 400_000);   --speed the i2c bus (scl) will run at in Hz
  PORT(
    clk       : IN     STD_LOGIC;                    --system clock
    reset_n   : IN     STD_LOGIC;                    --active low reset
    ena       : IN     STD_LOGIC;                    --latch in command
    addr      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
    rw        : IN     STD_LOGIC;                    --'0' is write, '1' is read
    data_wr   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
    busy      : OUT    STD_LOGIC;                    --indicates transaction in progress
    data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
    ack_error : BUFFER STD_LOGIC;                    --flag if improper acknowledge from slave
    sda       : INOUT  STD_LOGIC;                    --serial data output of i2c bus
    scl       : INOUT  STD_LOGIC);                   --serial clock output of i2c bus
END component;

begin

Inst_i2c_master: i2c_master 
		port map (
			addr => sevenseg_addr,
			data_wr => data,
			clk => clk,
			reset_n => reset_n,
			ena => i2c_en,
			rw => '0',
			busy => i2c_busy,
			ack_error => i2c_err,
			data_rd=> open, --we are not reading during this project
			sda => sda,
			scl => scl
		);

process(byteSel, dataIn)
 begin
    case byteSel is
       when 0  => data <= X"76";
       when 1  => data <= X"76";
       when 2  => data <= X"76";       
       when 3  => data <= X"7A";
       when 4  => data <= X"FF";
       when 5  => data <= X"77";
       when 6  => data <= X"00";
       when 7  => data <= X"79";
       when 8  => data <= X"00"; 
       when 9  => data <= x"0"&dataIn(15 downto 12);
       when 10 => data <= x"0"&dataIn(11 downto 8);
       when 11 => data <= x"0"&dataIn(7  downto 4);
       when 12 => data <= x"0"&dataIn(3  downto 0);
       when others => data <= x"76";
   end case;
end process;


process(clk, reset_n)
	begin
		if (rising_edge(clk)) then
						next_data<=dataIn;
						busy_prev <= i2c_busy;
			case state is
				when start =>
					if counter/= X"00000" then
						counter <= counter - 1 ;
						reset_n <='0';
						state   <= start;
						i2c_en <= '0';
						--i2c_data <= data;
					else
						reset_n <='1';
						i2c_en <= '1';
						state<=write2LED; --??
						end if;
				when write2LED =>
					if (i2c_busy ='0' and busy_prev /=i2c_busy) then
						if byteSel /= 12 then
							byteSel <= byteSel + 1;
							state<=write2LED;
						else	 
							byteSel <= 7;
							state <= stop;
						end if;
					end if;
				when stop =>
					i2c_en<='0';
					if next_data /= dataIn then	
						state<= start;
						counter<=X"03FFF";
					else 
						state<= stop;
					end if;
						
--				when ready =>		
--					if busy = '0' then
--						i2c_en <= '1';
--						state <= data_valid;
--					end if;
--				when data_valid =>
--					if busy = '1' then  
--						i2c_en <= '0';
--						state <= busy_high;
--					end if;
--				when busy_high =>
--					if(busy = '0') then 
--						state <= repeat;
--					end if;
--				when repeat => 
--					if byteSel < 11 then
--						byteSel <= byteSel + 1;
--					else	 
--						byteSel <= 9;           
--					end if;   
--					state <= start; 
				when others => null;
			end case;
		end if;
	end process;	
end Behavioral;