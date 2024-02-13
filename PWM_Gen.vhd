library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity PWM_Module is
    Port ( clk : in STD_LOGIC;
           reset: in STD_LOGIC;
			  freq_state: in std_logic_vector(1 downto 0); --freq_select
			  Data: in std_logic_vector(7 downto 0); 	--data in from sram/rom truncated to 8 bits
			  PWM_pulse: out STD_LOGIC
			  );
end PWM_Module;

architecture Behavioral of PWM_Module is
	 signal counter_60: std_logic_vector(7 downto 0);
	 signal counter_120: std_logic_vector(6 downto 0);
	 signal counter_1000: std_logic_vector(5 downto 0);
    signal PWM_pulse_sig: std_logic:='0';
	 signal enable: std_logic:='1';
	 signal prev_data: std_logic_vector(7 downto 0):=x"00";
	 
begin

	 process(clk,reset)
    begin
		if reset = '1' then
			counter_60 <= (others => '0');
		elsif rising_edge(clk) then
			if enable= '1' then
				counter_60 <= counter_60 +'1';
				
--				if(Data /= prev_data) or counter = x"FF" then
--					counter <= (others => '0');
--				end if;

			case freq_state is
				when "00" =>	--60Hz
				if(counter_60 <= Data) then
					PWM_pulse_sig <= '1';
				else --need to figure out when to reset to get 60 Hz	
					PWM_pulse_sig <= '0';
				end if;
				
				when "01" => --120 Hz
				if(counter_60 <= Data) then
					PWM_pulse_sig <= '1';
				else --need to figure out when to reset to get 120 Hz	
					PWM_pulse_sig <= '0';
				end if;
				
				when "10" => --1000 Hz
				if(counter_60 <= Data) then
					PWM_pulse_sig <= '1';
				else --need to figure out when to reset to get 1000 Hz
					PWM_pulse_sig <= '0';
				end if;
				
				when others =>
			end case;
			end if;
		end if;
		
			
    end process;
	  process(clk, reset)
			begin
			if reset = '1' then
				prev_data <= (others => '0');
			elsif rising_edge(clk) then
				prev_data <= Data;
			end if;
			end process;
	 
	 PWM_pulse<= PWM_pulse_sig;
	 
		
end Behavioral;
