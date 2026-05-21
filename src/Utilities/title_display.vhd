library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.utils.all;

entity title_display is

	generic (
		text_string : string := "FLAPPY BOSS";
		text_size : integer := 11;
		SIZE : integer := 4
	);

    port (
        clk          : in  std_logic;
        pixel_row    : in  std_logic_vector(9 downto 0);
        pixel_column : in  std_logic_vector(9 downto 0);
        pixel_on     : out std_logic;
        text_row : in integer;
        text_col_start : in integer
		  
    );
end entity title_display;

architecture behaviour of title_display is

    component char_rom is
        port (
            character_address : in std_logic_vector(5 downto 0);
            font_row          : in std_logic_vector(2 downto 0);
            font_col          : in std_logic_vector(2 downto 0);
            clock             : in std_logic;
            rom_mux_output    : out std_logic
        );
    end component char_rom;
	 type char_array is array (text_size downto 0) of std_logic_vector(5 downto 0);
		 
	function CONV_TEXT_TO_ARRAY return char_array is
		variable result : char_array := (others => O"40");
	begin
		for i in 1 to text_size loop
			result(i-1) := char_to_addr(text_string(i));
		end loop;

		return result;
	end function CONV_TEXT_TO_ARRAY;
    
	constant title_string : char_array := CONV_TEXT_TO_ARRAY;
	 
    constant char_width : integer := (2**(SIZE+1));
    constant char_height : integer := (2**(SIZE+1));
    constant num_chars : integer := text_size;

    signal char_index : integer;
    signal char_addr  : std_logic_vector(5 downto 0);

    signal font_row_full : std_logic_vector(9 downto 0);
    signal font_col_full : std_logic_vector(9 downto 0);

    signal font_row_sig : std_logic_vector(2 downto 0);
    signal font_col_sig : std_logic_vector(2 downto 0);
    signal rom_out : std_logic;
    signal in_text_zone  : std_logic;

    signal row_int : integer;
    signal col_int : integer;
    


	 
begin 

	 
    row_int <= to_integer(unsigned(pixel_row));
    col_int <= to_integer(unsigned(pixel_column));

    in_text_zone <= '1' when (row_int >= text_row and row_int < text_row + char_height and col_int >= text_col_start and col_int < text_col_start + num_chars * char_width) else '0';

    -- Determines which character we are currently displaying
    char_index <= (col_int - text_col_start) / char_width when in_text_zone = '1' else 0;

    font_row_full <= std_logic_vector(to_unsigned((row_int - text_row) mod char_height, 10)) when in_text_zone = '1' else (others => '0');
    font_col_full <= std_logic_vector(to_unsigned((col_int - text_col_start) mod char_width, 10)) when in_text_zone = '1' else (others => '0');

    font_row_sig <= font_row_full(SIZE downto SIZE-2);
    font_col_sig <= font_col_full(SIZE downto SIZE-2);

    char_addr <= title_string(char_index) when in_text_zone = '1' else (others => '0');

    CHAR_ROM_INST : char_rom
        port map (
            character_address => char_addr,
            font_row          => font_row_sig,
            font_col          => font_col_sig,
            clock             => clk,
            rom_mux_output    => rom_out
        );

    pixel_on <= rom_out when in_text_zone = '1' else '0';

end architecture behaviour;