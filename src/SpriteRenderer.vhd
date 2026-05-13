library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.sprite_data_pkg.all;

entity SpriteRenderer is
    port (
        clk : in std_logic;
        pixel_row    : in std_logic_vector(9 downto 0);
        pixel_column : in std_logic_vector(9 downto 0);
        start_x  : in std_logic_vector(9 downto 0);
        start_y  : in std_logic_vector(9 downto 0);
        sprite_id : in integer;
        red   : out std_logic_vector(3 downto 0);
        green : out std_logic_vector(3 downto 0);
        blue  : out std_logic_vector(3 downto 0);
		transparent : out std_logic
    );
end entity;

architecture behavior of SpriteRenderer is

    signal sprite_x : integer;
    signal sprite_y : integer;
    signal sprite_width : integer;
    signal sprite_height : integer;

begin

    sprite_x <= to_integer(unsigned(start_x));
    sprite_y <= to_integer(unsigned(start_y));

    process(clk)

        variable screen_x : integer;
        variable screen_y : integer;

        variable local_x : integer;
        variable local_y : integer;

        variable addr : integer;

        variable palette_index : integer;

        variable color : std_logic_vector(11 downto 0);
        variable width : integer;
        variable height : integer;

    begin

        if rising_edge(clk) then

            screen_x := to_integer(unsigned(pixel_column));
            screen_y := to_integer(unsigned(pixel_row));

            -- default black
            red   <= "0000";
            green <= "0000";
            blue  <= "0000";
            transparent <= '1';

            -- Get the sprite dimensions
            case sprite_id is
                when 0 =>
                    width := SKELETRON_HEAD_WIDTH;
                    height := SKELETRON_HEAD_HEIGHT;
                when 1 =>
                    width := SKELETRON_JAW_WIDTH;
                    height := SKELETRON_JAW_HEIGHT;
                when others =>
                    width := SKELETRON_HEAD_WIDTH;
                    height := SKELETRON_HEAD_HEIGHT;
            end case;

            -- Check if the current pixel is within the sprite's bounding box
            if screen_x >= sprite_x and
               screen_x < sprite_x + width and
               screen_y >= sprite_y and
               screen_y < sprite_y + height then

                local_x := screen_x - sprite_x;
                local_y := screen_y - sprite_y;

                -- used to search thru the 1d array to find the "2d" pixel pallete data.
                -- cuz the data is actually 1d array and not a 2d array.
                addr := local_y * width + local_x;

                -- Select the colors using the sprite we are rendering
                case sprite_id is
                    when 0 =>
                        palette_index := SKELETRON_HEAD_DATA(addr);
                        color := SKELETRON_HEAD_PALETTE(palette_index);
                    when 1 =>
                        palette_index := SKELETRON_JAW_DATA(addr);
                        color := SKELETRON_JAW_PALETTE(palette_index);
                    when others =>
                        palette_index := SKELETRON_HEAD_DATA(addr);
                        color := SKELETRON_HEAD_PALETTE(palette_index);
                end case;

                -- Check for transparency (palette index 0 is transparent)
                if (palette_index /= 0) then
                    red   <= color(11 downto 8);
                    green <= color(7 downto 4);
                    blue  <= color(3 downto 0);
                    transparent <= '0';
                else
                    transparent <= '1';
                end if;
            end if;
        end if;
    end process;
end architecture;