library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.sprite_data_pkg.all;

entity SpriteSheetRenderer is
    generic (
        SCALE_FACTOR : integer := 1;
        FRAME_WIDTH  : integer := 32;
        FRAME_HEIGHT : integer := 32
    );
    port (
        clk          : in std_logic;
        pixel_row    : in std_logic_vector(9 downto 0);
        pixel_column : in std_logic_vector(9 downto 0);
        start_x      : in std_logic_vector(10 downto 0);
        start_y      : in std_logic_vector(10 downto 0);
        frame_index  : in integer range 0 to 31; -- Which frame in the sheet to show
        sprite_id    : in integer range 0 to 64;
        red, green, blue : out std_logic_vector(3 downto 0);
        transparent  : out std_logic
    );
end entity;

architecture behavior of SpriteSheetRenderer is
begin
    process(clk)
        variable screen_x, screen_y : integer;
        variable local_x, local_y   : integer;
        variable sprite_x, sprite_y : integer;
        variable addr               : integer;
        variable palette_index      : integer;
        variable color              : std_logic_vector(11 downto 0);
        
        -- We need to know the total width of the "Sheet" array to wrap rows correctly
        variable sheet_total_width  : integer;
        
        -- Scaled bounding box
        variable scaled_w, scaled_h : integer;
    begin
        if rising_edge(clk) then
            screen_x := to_integer(unsigned(pixel_column));
            screen_y := to_integer(unsigned(pixel_row));
            sprite_x := to_integer(unsigned(start_x));
            sprite_y := to_integer(unsigned(start_y));

            -- Default Output
            red <= "0000"; green <= "0000"; blue <= "0000";
            transparent <= '1';

            -- 1. Determine Sheet Properties
            -- NOTE: sheet_total_width is the width of the ENTIRE sprite sheet image
            case sprite_id is
                when 0 => -- Example: Your Growing Sprite Sheet
                    sheet_total_width := SKELETRON_FULL_SHEET_WIDTH;
                when others =>
                    sheet_total_width := SKELETRON_FULL_SHEET_WIDTH; -- Default to single frame
            end case;

            scaled_w := FRAME_WIDTH * SCALE_FACTOR;
            scaled_h := FRAME_HEIGHT * SCALE_FACTOR;

            -- 2. Check Bounding Box
            if screen_x >= sprite_x and screen_x < sprite_x + scaled_w and
               screen_y >= sprite_y and screen_y < sprite_y + scaled_h then

                -- 3. Calculate Local Coordinates (Unscaled)
                local_x := (screen_x - sprite_x) / SCALE_FACTOR;
                local_y := (screen_y - sprite_y) / SCALE_FACTOR;

                -- 4. Calculate Address with Frame Offset
                -- Logic: (Row offset) + (Frame horizontal offset) + (Column offset)
                addr := (local_y * sheet_total_width) + (frame_index * FRAME_WIDTH) + local_x;

                -- 5. Fetch Palette Data
                case sprite_id is
                    when 0 =>
                        palette_index := SKELETRON_FULL_SHEET_DATA(addr);
                        color := SKELETRON_FULL_SHEET_PALETTE(palette_index);
                    when others =>
                        palette_index := 0;
                        color := x"000";
                end case;

                -- 6. Transparency Check
                if (palette_index /= 0) then
                    red   <= color(11 downto 8);
                    green <= color(7 downto 4);
                    blue  <= color(3 downto 0);
                    transparent <= '0';
                end if;
            end if;
        end if;
    end process;
end architecture;