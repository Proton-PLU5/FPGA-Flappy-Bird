library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_level_entity is
    port (
        Clk : in std_logic;
    );
end top_level_entity;

architecture behavior of top_level_entity is
    
    component VGA_SYNC
        port(
            clock_25Mhz, red, green, blue : IN STD_LOGIC;
			red_out, green_out, blue_out, horiz_sync_out, vert_sync_out	: OUT STD_LOGIC;
			pixel_row, pixel_column: OUT STD_LOGIC_VECTOR(9 DOWNTO 0));
    end component;

    component ClockDivider
        port (
            Clk_in : in std_logic;
            Clk_out : out std_logic
        );
    end component;

    signal Clk25Mhz : std_logic;

begin

    Clock_Divider : ClockDivider
        port map (
            Clk_in => Clk,
            Clk_out => Clk25Mhz
        );

    VGA : VGA_SYNC
        -- Display white color to check if it works lol
        port map (
            clock_25Mhz => Clk25Mhz,
            red => "1111", 
            green => "1111",
            blue => "1111",
            red_out => open,
            green_out => open,
            blue_out => open,
            horiz_sync_out => open,
            vert_sync_out => open,
            pixel_row => open,
            pixel_column => open
        );
    

    
end architecture behavior;