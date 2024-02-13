library IEEE; 

use IEEE.STD_LOGIC_1164.ALL; 

use IEEE.STD_LOGIC_ARITH.ALL; 

use IEEE.STD_LOGIC_UNSIGNED.ALL; 

 

entity State_Machine is 

    Port ( clk : in STD_LOGIC; 
           clk_en : in STD_LOGIC; 
           rst : in STD_LOGIC; 
           keys : in STD_LOGIC_VECTOR(3 downto 0); 
           --data_valid_pulse : in STD_LOGIC; 
           counter : in STD_LOGIC_VECTOR(7 downto 0); 
           state : out STD_LOGIC_VECTOR(2 downto 0)
			  ); 

end State_Machine; 

architecture Behavioral of State_Machine is 

    type states is (INIT,Test,Pause,PWM_Generation); 

    signal current_state, next_state : states; 

    signal state_value : STD_LOGIC_VECTOR(2 downto 0); 
	 
    signal counter_prev : STD_LOGIC_VECTOR(7 downto 0); 	 
	signal power_on_flag: std_logic:='0';
begin 


    process(clk) 

    begin 
    if rising_edge(clk) then 
	 counter_prev <= counter;
	 end if;
	 end process;
 

    process(clk, rst, counter) 

    begin 

        if rst = '1' then 
            current_state <= INIT; 
				power_on_flag<='1';
 
        elsif counter = X"00" and counter_prev = X"FF" then 	--Maybe  why doesnt start at one?
				if power_on_flag = '1' then
					current_state <= Test; 
					power_on_flag<='0';
				elsif  keys(0)='1' then
					current_state <= Test;
				end if;
	
        elsif rising_edge(clk) and clk_en = '1' then 
		  
        case current_state is 

            when Test => 
					 if keys(0)='0' then 
                    current_state <= INIT; 
                elsif keys(1)='0' then 
                    current_state <= Pause; 
                elsif keys(2)= '0' then
                    current_state <= PWM_Generation; 
                end if; 
            when Pause => 
						if keys(1)='0'  then 
                    current_state <= Test;
                end if; 
            when PWM_Generation => 
					if keys(2)='0'  then 
                    current_state <= Test;
                end if; 
--				When INIT =>
--					if keys(0)='1' then
--						current_state <= Test;
--						end if;
            when others => 
                current_state <= INIT;  -- Reset to INIT state if in an unknown state 
        end case; 
        end if;
    end process; 

 

 with current_state select 

    state_value <= "011" when INIT, 

                   "110" when Test, 

                   "101" when Pause, 

                   "111" when PWM_Generation, 

                   "000" when others;  -- Default value for unknown states 

    state <= state_value;
 

end Behavioral; 

