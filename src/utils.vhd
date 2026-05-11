library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package char_convert is

    type char_array is array (natural range <>) of std_logic_vector(5 downto 0);

    function char_to_addr(c : character) return std_logic_vector;

end package char_convert;

package body char_convert is

function char_to_addr(c : character) return std_logic_vector is
begin
    case c is
        when 'A'    => return "000001"; -- O"01"
        when 'B'    => return "000010"; -- O"02"
        when 'C'    => return "000011"; -- O"03"
        when 'D'    => return "000100"; -- O"04"
        when 'E'    => return "000101"; -- O"05"
        when 'F'    => return "000110"; -- O"06"
        when 'G'    => return "000111"; -- O"07"
        when 'H'    => return "001000"; -- O"10"
        when 'I'    => return "001001"; -- O"11"
        when 'J'    => return "001010"; -- O"12"
        when 'K'    => return "001011"; -- O"13"
        when 'L'    => return "001100"; -- O"14"
        when 'M'    => return "001101"; -- O"15"
        when 'N'    => return "001110"; -- O"16"
        when 'O'    => return "001111"; -- O"17"
        when 'P'    => return "010000"; -- O"20"
        when 'Q'    => return "010001"; -- O"21"
        when 'R'    => return "010010"; -- O"22"
        when 'S'    => return "010011"; -- O"23"
        when 'T'    => return "010100"; -- O"24"
        when 'U'    => return "010101"; -- O"25"
        when 'V'    => return "010110"; -- O"26"
        when 'W'    => return "010111"; -- O"27"
        when 'X'    => return "011000"; -- O"30"
        when 'Y'    => return "011001"; -- O"31"
        when 'Z'    => return "011010"; -- O"32"
        when others => return "000000"; -- space/default
    end case;
end function;

end package body char_convert;