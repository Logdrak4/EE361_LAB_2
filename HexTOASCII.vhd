library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity HexToASCII is
    Port ( hex_digit : in STD_LOGIC_VECTOR (3 downto 0);
           ascii : out STD_LOGIC_VECTOR (7 downto 0));
end HexToASCII;

architecture Behavioral of HexToASCII is
begin
    process(hex_digit)
    begin
      case HEX_digit is
        when X"A" => ascii <=X"41";
        when X"B" => ascii <=X"42";
        when X"C" => ascii <=X"43";
        when X"D" => ascii <=X"44";
        when X"E" => ascii <=X"45";
        when X"F" => ascii <=X"46";
        when X"0" => ascii <=X"30";
        when X"1" => ascii <=X"31";
        when X"2" => ascii <=X"32";
        when X"3" => ascii <=X"33";
        when X"4" => ascii <=X"34";		--finish table to end of all ascii values
		  when X"5" => ascii <=X"35";
		  when X"6" => ascii <=X"36";
		  when X"7" => ascii <=X"37";
		  when X"8" => ascii <=X"38";
		  when X"9" => ascii <=X"39";
		  when others => ascii <=X"30";
       -- when others => null;
        end case;
    end process;
end Behavioral;
