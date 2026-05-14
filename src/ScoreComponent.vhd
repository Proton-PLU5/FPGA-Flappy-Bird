library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.utils.all;

entity ScoreTextRenderer is
    port (
        clk : in std_logic;
        score : in integer;
        pixel_row : in std_logic_vector(9 downto 0);
        pixel_column : in std_logic_vector(9 downto 0);
        pixel_on : out std_logic;
        text_row : in integer;
        text_col_start : in integer
    );
end entity ScoreTextRenderer;

architecture behavior of ScoreTextRenderer is
    component char_rom is
        port (
            character_address : in std_logic_vector(5 downto 0);
            font_row          : in std_logic_vector(2 downto 0);
            font_col          : in std_logic_vector(2 downto 0);
            clock             : in std_logic;
            rom_mux_output    : out std_logic
        );
    end component char_rom;
	
    type char_array is array (2 downto 0) of std_logic_vector(5 downto 0);
		 
	function CONV_TEXT_TO_ARRAY (i : integer range 0 to 999) return char_array is
		variable result : char_array := (others => O"40");
        variable digit0, digit1, digit2 : integer range 0 to 9;
	begin
		-- Break integer down to its digits
        -- Score will be 3 digits max.

        -- Digit 0 is the ones place
        digit0 <= i mod 10;
        digit1 <= ((i mod 100) - digit0) / 10;
        digit2 <= (i - (digit1 * 10) - digit0) / 100;
        
        result(0) <= int_to_addr(digit0);
        result(1) <= int_to_addr(digit1);
        result(2) <= int_to_addr(digit2);

		return result;
	end function CONV_TEXT_TO_ARRAY;

begin

end behavior;