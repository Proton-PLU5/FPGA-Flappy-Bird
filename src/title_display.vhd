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
            clock             : in std_logic;
            rom_mux_output    : out std_logic
        );
    end component char_rom;

    type char_array is array (11 downto 0) of std_logic_vector(5 downto 0);
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

    

begin 

