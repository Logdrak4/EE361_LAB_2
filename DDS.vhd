library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use ieee.numeric_std.all;
 
entity DDS is
    Port ( clk : in STD_LOGIC;
           reset: in STD_LOGIC;
			  state: in std_logic_vector(2 downto 0);
			  freq_state: in std_logic_vector(1 downto 0); --freq_select
			  addr: out std_logic_vector(7 downto 0)
			  );
end DDS;

architecture Behavioral of DDS is
	 signal counter: unsigned(31 downto 0):= x"00000000";
	 signal prev_freq: std_logic_vector(1 downto 0):="11";
    signal PWM_pulse_sig: std_logic:='0';
	 signal m: std_logic_vector(31 downto 0); --jump size
	 
begin

	addr<=std_logic_vector(counter(31 downto 24));
	
	 process(clk,reset)
    begin
		if reset = '1' or state /= "111" or freq_state /= prev_freq then
			counter <=(others=>'0');
		elsif rising_edge(clk) then
			if freq_state ="00" then
				counter <= counter + x"1421"; --"0001010000100001";
				m <= std_logic_vector(to_unsigned(5153, 32));
			end if;
			if freq_state ="01" then
				counter <= counter + x"2843";--"0010100001000011"; x"2843"
				m <=std_logic_vector(to_unsigned(10307, 32));
			end if;
			if freq_state ="10" then
				counter <= counter +  x"14F8B";--"00010100111110001011"; x"14F8B"
				m <=std_logic_vector(to_unsigned(85899, 32));
			end if;
		end if;
		
		end process;
			  process(clk, reset)
			begin
			if reset = '1' then
				prev_freq <= "11";
			elsif rising_edge(clk) then
				prev_freq <= freq_state;
			end if;
			end process;
	 
		
		
	
end Behavioral;

