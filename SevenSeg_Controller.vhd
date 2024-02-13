library ieee;
use ieee.std_logic_1164.all;

entity SevenSeg_Controller is
	generic(
		sevenseg_addr : std_logic_vector(6 downto 0) := "1110001" -- seven segment display address
	);
	port (
---------------------------------------------------------------------------------------------------------
-- Project
		dataIn : in std_logic_vector(15 downto 0); -- 4 hexadecimal digits to display to seven segment
		clk	: in	std_logic;	-- clock
		reset	: in	std_logic;	-- reset
---------------------------------------------------------------------------------------------------------
-- I2C
		sda	: inout  std_logic;	-- serial data output of I2C bus
		scl	: inout  std_logic	-- serial clock output of I2C bus
);
end SevenSeg_Controller;

architecture Behavioral of SevenSeg_Controller is
---------------------------------------------------------------------------------------------------------
-- Signals
type state_type is(start, ready, data_valid, busy_high, repeat);
signal state : state_type:=start;
signal data : std_logic_vector(7 downto 0);
signal i2c_data : std_logic_vector(7 downto 0);
signal i2c_en, i2c_res, i2c_err, i2c_busy : std_logic;
signal busy, busy_prev, busy_fall : std_logic;
signal sda_sig, scl_sig : std_logic;
signal byteSel : integer range 0 to 12:=0;

component I2C_Controller is
	port(
		addr		: in	std_logic_vector(6 downto 0); --address of target peripheral
		dataIn	: in	std_logic_vector(7 downto 0); --data to write to peripheral
		dataOut	: out	std_logic_vector(7 downto 0); --data read from peripheral
		clk	: in	std_logic;	-- clock
		reset	: in	std_logic;	-- reset
		en		: in	std_logic;	-- enable
		rw		: in	std_logic;	-- read/write flag 1 = read / 0 = write
		busy	: out	std_logic;	-- 1 = busy / 0 = not busy
		ack_error : buffer std_logic;	-- flag if improper acknowledge from peripheral
		sda	: inout  std_logic;	-- serial data output of I2C bus
		scl	: inout  std_logic	-- serial clock output of I2C bus
	);
end component;

begin

Inst_I2C_Controller: I2C_Controller 
		port map (
			addr => sevenseg_addr,
			dataIn => i2c_data,
			clk => clk,
			reset => i2c_res,
			en => i2c_en,
			rw => '0',
			busy => i2c_busy,
			ack_error => i2c_err,
			sda => sda_sig,
			scl => scl_sig
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


process(clk, reset)
	begin
		if (rising_edge(clk)) then
		
			busy_prev <= busy;
			busy <= i2c_busy;
--			if (busy = '0' and busy_prev = '1') then
--				busy_fall <= '1'; --falling edge of busy signal
--			else
--				busy_fall <= '0'; --no falling edge of busy signal
--			end if;
		
			case state is
				when start =>
					state   <= ready;
					i2c_data <= data;
				when ready =>		
					if busy = '0' then
						i2c_en <= '1';
						state <= data_valid;
					end if;
				when data_valid =>
					if busy = '1' then  
						i2c_en <= '0';
						state <= busy_high;
					end if;
				when busy_high =>
					if(busy = '0') then 
						state <= repeat;
					end if;
				when repeat => 
					if byteSel < 11 then
						byteSel <= byteSel + 1;
					else	 
						byteSel <= 9;           
					end if;   
					state <= start; 
				when others => null;
			end case;
		end if;
	end process;	
end Behavioral;
