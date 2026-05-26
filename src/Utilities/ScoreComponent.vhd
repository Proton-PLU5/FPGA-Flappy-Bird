library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.utils.all;

entity ScoreTextRenderer is
    generic (
        SIZE : integer := 4
    );

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
        variable temp : integer range 0 to 999;
        variable digit0, digit1, digit2 : integer range 0 to 9;
	begin
		-- Break integer down to its digits without division/mod.
        temp := i;
        digit0 := 0;
        digit1 := 0;
        digit2 := 0;

        if temp >= 900 then
            digit2 := 9; temp := temp - 900;
        elsif temp >= 800 then
            digit2 := 8; temp := temp - 800;
        elsif temp >= 700 then
            digit2 := 7; temp := temp - 700;
        elsif temp >= 600 then
            digit2 := 6; temp := temp - 600;
        elsif temp >= 500 then
            digit2 := 5; temp := temp - 500;
        elsif temp >= 400 then
            digit2 := 4; temp := temp - 400;
        elsif temp >= 300 then
            digit2 := 3; temp := temp - 300;
        elsif temp >= 200 then
            digit2 := 2; temp := temp - 200;
        elsif temp >= 100 then
            digit2 := 1; temp := temp - 100;
        else
            digit2 := 0;
        end if;

        if temp >= 90 then
            digit1 := 9; temp := temp - 90;
        elsif temp >= 80 then
            digit1 := 8; temp := temp - 80;
        elsif temp >= 70 then
            digit1 := 7; temp := temp - 70;
        elsif temp >= 60 then
            digit1 := 6; temp := temp - 60;
        elsif temp >= 50 then
            digit1 := 5; temp := temp - 50;
        elsif temp >= 40 then
            digit1 := 4; temp := temp - 40;
        elsif temp >= 30 then
            digit1 := 3; temp := temp - 30;
        elsif temp >= 20 then
            digit1 := 2; temp := temp - 20;
        elsif temp >= 10 then
            digit1 := 1; temp := temp - 10;
        else
            digit1 := 0;
        end if;

        digit0 := temp;
        
        result(0) := int_to_addr(digit0);
        result(1) := int_to_addr(digit1);
        result(2) := int_to_addr(digit2);

		return result;
	end function CONV_TEXT_TO_ARRAY;

    constant char_width : integer := (2**(SIZE+1));
    constant char_height : integer := (2**(SIZE+1));
    constant num_chars : integer := 3;

    signal char_index : integer;
    signal char_addr  : std_logic_vector(5 downto 0);

    signal row_offset_u : unsigned(9 downto 0);
    signal col_offset_u : unsigned(9 downto 0);

    signal font_row_sig : std_logic_vector(2 downto 0);
    signal font_col_sig : std_logic_vector(2 downto 0);
    signal rom_out : std_logic;
    signal in_text_zone  : std_logic;

    signal text_string : char_array;

    signal row_int : integer;
    signal col_int : integer;
begin
    row_int <= to_integer(unsigned(pixel_row));
    col_int <= to_integer(unsigned(pixel_column));

    text_string <= CONV_TEXT_TO_ARRAY(score);

    in_text_zone <= '1' when (row_int >= text_row and row_int < text_row + char_height and col_int >= text_col_start and col_int < text_col_start + num_chars * char_width) else '0';

    row_offset_u <= to_unsigned(row_int - text_row, 10) when in_text_zone = '1' else (others => '0');
    col_offset_u <= to_unsigned(col_int - text_col_start, 10) when in_text_zone = '1' else (others => '0');

    -- Determines which character we are currently displaying (power-of-two divide via bit slice)
    char_index <= to_integer(col_offset_u(9 downto SIZE+1)) when in_text_zone = '1' else 0;

    font_row_sig <= std_logic_vector(row_offset_u(SIZE downto SIZE-2));
    font_col_sig <= std_logic_vector(col_offset_u(SIZE downto SIZE-2));

    char_addr <= text_string(2 - char_index) when in_text_zone = '1' else (others => '0');

    CHAR_ROM_INST : char_rom
        port map (
            character_address => char_addr,
            font_row          => font_row_sig,
            font_col          => font_col_sig,
            clock             => clk,
            rom_mux_output    => rom_out
        );

    pixel_on <= rom_out when in_text_zone = '1' else '0';
end behavior;