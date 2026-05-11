library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity title_display is
    port (
        clk          : in  std_logic;
        pixel_row    : in  std_logic_vector(9 downto 0);
        pixel_column : in  std_logic_vector(9 downto 0);
        pixel_on     : out std_logic
    );
end title_display;

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

    type char_array is array (10 downto 0) of std_logic_vector(5 downto 0);
    constant title_string : char_array := (
        -- "Flappy Bird"
        O"06",
        O"14",
        O"01",
        O"20",
        O"20",
        O"31",
        O"40",
        O"02",
        O"11",
        O"22",
        O"04"
    );

    constant text_row : integer := 100;
    constant text_col_start : integer := 160;
    constant char_width : integer := 8;
    constant char_height : integer := 8;
    constant num_chars : integer := 11;

    signal char_index : integer range 0 to 15;
    signal char_addr  : std_logic_vector(5 downto 0);
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
    char_index <= (col_int - text_col_start) / char_width;

    font_row_sig <= std_logic_vector(to_unsigned((row_int - text_row) mod char_height, 3));
    font_col_sig <= std_logic_vector(to_unsigned((col_int - text_col_start) mod char_width, 3));

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




end architecture behaviour;