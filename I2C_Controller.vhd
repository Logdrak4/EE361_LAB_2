library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity I2C_Controller is
	generic(
		input_clk : integer := 50_000_000;	--input clock speed from user logic in Hz
		bus_clk   : integer := 100_000		--speed the i2c bus (scl) will run at in Hz
	);
	port(
---------------------------------------------------------------------------------------------------------
-- Project interactions
		addr		: in	std_logic_vector(6 downto 0); --address of target peripheral
		dataIn	: in	std_logic_vector(7 downto 0); --data to write to peripheral
		dataOut	: out	std_logic_vector(7 downto 0); --data read from peripheral

		clk	: in	std_logic;	-- clock
		reset	: in	std_logic;	-- reset
		en		: in	std_logic;	-- enable
		rw		: in	std_logic;	-- read/write flag 1 = read / 0 = write
		busy	: out	std_logic;	-- 1 = busy / 0 = not busy

		ack_error : buffer std_logic;	-- flag if improper acknowledge from peripheral
---------------------------------------------------------------------------------------------------------
-- I2C interactions
		sda	: inout  std_logic;	-- serial data output of I2C bus
		scl	: inout  std_logic	-- serial clock output of I2C bus
	);
end I2C_Controller;
architecture logic of I2C_Controller is
---------------------------------------------------------------------------------------------------------
-- Signals
	type state_type is	(ready, start, command, per_ack1, per_ack2, con_ack, wr, rd, stop);
	signal state			: state_type;
	constant divider		: integer := (input_clk/bus_clk)/4;	--number of clocks in 1/4 cycle of scl
	signal data_clk      : std_logic;	--data clock for sda
	signal data_clk_prev : std_logic;	--data clock during previous system clock
	signal data_clk_m    : std_logic;	--data clock during previous system clock
	signal scl_clk       : std_logic;	--constantly running internal scl
	signal scl_en        : std_logic := '0';	--enbles internal scl to output
	signal sda_int       : std_logic := '1';	--internal sda
	signal sda_en_n      : std_logic;	--enbles internal sda to output
	signal addr_rw       : std_logic_vector(7 downto 0);	--latched in address and read/write
	signal data_tx       : std_logic_vector(7 downto 0);	--latched in data to write to peripheral
	signal data_rx       : std_logic_vector(7 downto 0);	--data received from peripheral
	signal bit_cnt       : integer RANGE 0 to 7 := 7;	--tracks bit number in transaction
	signal stretch       : std_logic := '0';	--identifies if peripheral is stretching scl
begin
---------------------------------------------------------------------------------------------------------
-- Connections
	--set sda output
	data_clk_m <= data_clk_prev and data_clk;         -- Modification added at CU
	with state select
	sda_en_n <= data_clk when start,		--generate start condition
		not data_clk_m when stop,			--generate stop condition (modification added at CU)
		sda_int when others;					--set to internal sda signal
      
	--set scl and sda outputs
	scl <= '0' when (scl_en = '1' AND scl_clk = '0') else 'Z';
	sda <= '0' when sda_en_n = '0' else 'Z';
  
-- Following two signals will be used for tristate obuft (did not work)
--  scl <= '1' when (scl_en = '1' AND scl_clk = '0') else '0';
--  sda <= '1' when sda_en_n = '0' else '0';

--------------------------------------------------------------------------------------------------------
--generate the timing for the bus clock (scl_clk) and the data clock (data_clk)
process(clk, reset)
	variable count : integer range 0 to divider*4;	--counter for clock generation
	begin
	if(reset = '1') then	-- reset
		stretch <= '0';
		count := 0;
	elsif(rising_edge(clk)) then
		data_clk_prev <= data_clk;			--store previous value of data clock
		if(count = divider*4) then
			count := 0;							--reset counter if max count reached
		elsif(stretch = '0') then			
			count := count + 1;				--increment counter if no clock stretching detected
		end if;
		case count is
			---1st 4th of cycle of clock
			when 0 to ((divider*4)/4) - 1 =>
				scl_clk <= '0';
				data_clk <= '0';
			--2nd 4th of cycle of clock
			when (divider*4)/4 to (divider*4)/2 - 1 =>
				scl_clk <= '0';
				data_clk <= '1';
			-- 3rd 4th of cycle of clock
			when (divider*4)/2 to ((divider*4)/4) + ((divider*4)/2) - 1 =>
				scl_clk <= '1';		--release scl
				if(scl = '0') then	--detect if peripheral is stretching clock
					stretch <= '1';
				else
					stretch <= '0';
				end if;
				data_clk <= '1';
			--4th 4th of cycle of clock
			when others =>                    
				scl_clk <= '1';
				data_clk <= '0';
		end case;
	end if;
end process;
---------------------------------------------------------------------------------------------------------
--state machine and writing to sda during scl low (data_clk rising edge)
process(clk, reset)
begin
	if(reset = '1') then		--reset
		state <= ready;		--return to initial state
		busy <= '1';			--indicate not available
		scl_en <= '0';			--sets scl high impedance
		sda_int <= '1';		--sets sda high impedance
		ack_error <= '0';		--clear acknowledge error flag
		bit_cnt <= 7;			--restarts data bit counter
		dataOut <= x"00";		--clear data read port
	elsif(rising_edge(clk)) then
		if(data_clk = '1' AND data_clk_prev = '0') then --data clock rising edge
			case state is
				when ready =>
					if(en = '1') then
						busy <= '1';
						addr_rw <= addr & rw; 	--combine address and rw flag
						data_tx <= dataIn;		--write dataIn to register
						state <= start;
					else
						busy <= '0';
						state <= ready;
					end if;
				when start =>
					busy <= '1';
					sda_int <= addr_rw(bit_cnt);     --set first address bit to bus
					state <= command;
				when command =>                    --address and command byte of transaction
					if(bit_cnt = 0) then             --command transmit finished
						sda_int <= '1';                --release sda for peripheral acknowledge
						bit_cnt <= 7;                  --reset bit counter for "byte" states
						state <= per_ack1;             --go to peripheral acknowledge (command)
					else                             --next clock cycle of command state
						bit_cnt <= bit_cnt - 1;        --keep track of transaction bits
						sda_int <= addr_rw(bit_cnt-1); --write address/command bit to bus
						state <= command;              --continue with command
					end if;
				when per_ack1 =>                   --peripheral acknowledge bit (command)
					if(addr_rw(0) = '0') then        --write command
						sda_int <= data_tx(bit_cnt);   --write first bit of data
						state <= wr;                   --go to write byte
					else                             --read command
						sda_int <= '1';                --release sda from incoming data
						state <= rd;                   --go to read byte
					end if;
				when wr =>                         --write byte of transaction
					busy <= '1';                     --resume busy if continuous mode
					if(bit_cnt = 0) then             --write byte transmit finished
						sda_int <= '1';                --release sda for peripheral acknowledge
						bit_cnt <= 7;                  --reset bit counter for "byte" states
-- added the following line to make sure busy = 0 in the per_ack2 state              
						busy <= '0';                   --continue is accepted    (modified by CU)          
						state <= per_ack2;             --go to peripheral acknowledge (write)
					else                             --next clock cycle of write state
						bit_cnt <= bit_cnt - 1;        --keep track of transaction bits
						sda_int <= data_tx(bit_cnt-1); --write next bit to bus
						state <= wr;                   --continue writing
					end if;
				when rd =>                         --read byte of transaction
					busy <= '1';                     --resume busy if continuous mode
					if(bit_cnt = 0) then             --read byte receive finished
						if(en = '1' AND addr_rw = addr & rw) then  --continuing with another read at same address
							sda_int <= '0';              --acknowledge the byte has been received
						else                           --stopping or continuing with a write
							sda_int <= '1';              --send a no-acknowledge (before stop or repeated start)
						end if;
						bit_cnt <= 7;                  --reset bit counter for "byte" states
--    added the following line to make sure busy = 0 in the con_ack state              
						busy <= '0';                   --continue is accepted    (modified by CU)              
						dataOut <= data_rx;            --output received data
						state <= con_ack;             --go to controller acknowledge
					else                             --next clock cycle of read state
						bit_cnt <= bit_cnt - 1;        --keep track of transaction bits
						state <= rd;                   --continue reading
					end if;
				when per_ack2 =>                   --peripheral acknowledge bit (write)
					if(en = '1') then               --continue transaction
						--busy <= '0';                   --continue is accepted   (modified by CU)           
						addr_rw <= addr & rw;          --collect requested peripheral address and command
						data_tx <= dataIn;            --collect requested data to write
						if(addr_rw = addr & rw) then   --continue transaction with another write
							busy <= '1';                 --resume busy in the wr state (modified by CU)             
							sda_int <= dataIn(bit_cnt); --write first bit of data
							state <= wr;                 --go to write byte
						else                           --continue transaction with a read or new peripheral
							state <= start;              --go to repeated start
						end if;
					else                             --complete transaction
						busy <= '0';                   --unflag busy  (modified by CU)
						sda_int <= '1';                --sets sda high impedance (modified by CU)             
						state <= stop;                 --go to stop bit
					end if;
				when con_ack =>                   --controller acknowledge bit after a read
					if(en = '1') then               --continue transaction
						--busy <= '0';                   --continue is accepted   (modified by CU)
						addr_rw <= addr & rw;          --collect requested peripheral address and command
						data_tx <= dataIn;            --collect requested data to write
						if(addr_rw = addr & rw) then   --continue transaction with another read
							busy <= '1';                 --resume busy in the wr state (modified by CU)               
							sda_int <= '1';              --release sda from incoming data
							state <= rd;                 --go to read byte
						else                           --continue transaction with a write or new peripheral
							state <= start;              --repeated start
						end if;    
					else                             --complete transaction
						busy <= '0';                   --unflag busy  (modified by CU)
						sda_int <= '1';                --sets sda high impedance (modified by CU)
						state <= stop;                 --go to stop bit                             
					end if;
				when stop =>                       --stop bit of transaction
					--busy <= '0';                   --unflag busy  (modified by CU)           
					state <= ready;                --go to idle state
			end case;    
      elsif(data_clk = '0' AND data_clk_prev = '1') then  --data clock falling edge
			case state is
				when start =>                  
					if(scl_en = '0') then                  --starting new transaction
						scl_en <= '1';                       --enble scl output
						ack_error <= '0';                     --reset acknowledge error output
					end if;
				when per_ack1 =>                          --receiving peripheral acknowledge (command)
					if(sda /= '0' OR ack_error = '1') then  --no-acknowledge or previous no-acknowledge
						ack_error <= '1';                     --set error output if no-acknowledge
					end if;
				when rd =>                                --receiving peripheral data
					data_rx(bit_cnt) <= sda;                --receive current peripheral data bit
				when per_ack2 =>                          --receiving peripheral acknowledge (write)
					if(sda /= '0' OR ack_error = '1') then  --no-acknowledge or previous no-acknowledge
						ack_error <= '1';                     --set error output if no-acknowledge
					end if;
				when stop =>
					scl_en <= '0';                         --disable scl
				when others =>
					null;
			end case;
		end if;
	end if; 
end process;  
  
end logic;
