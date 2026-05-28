library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.sprite_data_pkg.all;

entity SpriteRenderer is
    generic (
        SCALE_FACTOR : integer := 1
    );
    port (
        clk : in std_logic;
        pixel_row    : in std_logic_vector(9 downto 0);
        pixel_column : in std_logic_vector(9 downto 0);
        start_x  : in std_logic_vector(10 downto 0);
        start_y  : in std_logic_vector(10 downto 0);
        sprite_id : in integer range 0 to 64;
        flip_y  : in std_logic := '0';
        red   : out std_logic_vector(3 downto 0);
        green : out std_logic_vector(3 downto 0);
        blue  : out std_logic_vector(3 downto 0);
        transparent : out std_logic
    );
end entity;

architecture behavior of SpriteRenderer is

    signal sprite_x : integer;
    signal sprite_y : integer;

begin
    -- use integers since we have width and height as integers and its easier to do math by
    -- just turning them all into integers than having convert them each time.
    -- in the future we MUST add some range constraints to reduce the amount of bits we use.
    -- Cuz these use soooo much resources and i think its cuz of these that the compile times are so long.
    
    sprite_x <= to_integer(unsigned(start_x));
    sprite_y <= to_integer(unsigned(start_y));

    process(clk)
        variable screen_x : integer range 0 to 640;
        variable screen_y : integer range 0 to 480;
        variable local_x : integer range 0 to 640;
        variable local_y : integer range 0 to 480;
        variable addr : integer range 0 to 307199;
        variable palette_index : integer range 0 to 255;
        variable color : std_logic_vector(11 downto 0);
        variable width : integer range 0 to 640;
        variable height : integer range 0 to 480;
        variable scaled_width : integer range 0 to 640;
        variable scaled_height : integer range 0 to 480;
    begin

        if rising_edge(clk) then
            
            screen_x := to_integer(unsigned(pixel_column));
            screen_y := to_integer(unsigned(pixel_row));

            -- default black
            red   <= "0000";
            green <= "0000";
            blue  <= "0000";
            transparent <= '1';

            -- Get the sprite dimensions (original unscaled size)
            case sprite_id is
                when 0 =>
                    width := SKELETRON_HEAD_WIDTH;
                    height := SKELETRON_HEAD_HEIGHT;
                when 1 =>
                    width := SKELETRON_JAW_WIDTH;
                    height := SKELETRON_JAW_HEIGHT;
                when 2 =>
                    width := FLAPPY_BIRD_WIDTH;
                    height := FLAPPY_BIRD_HEIGHT;
                when 3 =>
                    width := FULL_HEART_WIDTH;
                    height := FULL_HEART_HEIGHT;
                when 4 =>
                    width := EMPTY_HEART_WIDTH;
                    height := EMPTY_HEART_HEIGHT;
                when 5 =>
                    width := BLUE_BRICK_TILE_WIDTH;
                    height := BLUE_BRICK_TILE_HEIGHT;
                when 6 =>
                    width := LASER_BEAM_WARNING_WIDTH;
                    height := LASER_BEAM_WARNING_HEIGHT;
                when 7 =>
                    width := LASER_BEAM_WIDTH;
                    height := LASER_BEAM_HEIGHT;
                when 8 =>
                    width := L3SKULL_WIDTH;
                    height := L3SKULL_HEIGHT;
                when 9 =>
                    width := POWERUP_WIDTH;
                    height := POWERUP_HEIGHT;
                when 10 =>
                    width := BONE_BODY_WIDTH;
                    height := BONE_BODY_HEIGHT;
                when 11 =>
                    width := BONE_CAP_WIDTH;
                    height := BONE_CAP_HEIGHT;
                when 12 =>
                    width := BONE_BODY_2_WIDTH;
                    height := BONE_BODY_2_HEIGHT;
                when 13 =>
                    width := BONE_CAP_2_WIDTH;
                    height := BONE_CAP_2_HEIGHT;
                when 14 => 
                    width := DARK_BRICK_TILE_WIDTH;
                    height := DARK_BRICK_TILE_HEIGHT;
                when 15 =>
                    width := BRICK_TILE_WIDTH;
                    height := BRICK_TILE_HEIGHT;
                when others =>
                    width := SKELETRON_HEAD_WIDTH;
                    height := SKELETRON_HEAD_HEIGHT;
            end case;

            -- Calculate scaled widths and heights
            scaled_width := width * SCALE_FACTOR;
            scaled_height := height * SCALE_FACTOR;

            -- Check if the current pixel is within the scaled sprite's bounding box
            if screen_x >= sprite_x and
               screen_x < sprite_x + scaled_width and
               screen_y >= sprite_y and
               screen_y < sprite_y + scaled_height then

                -- Calculate the local pixel coordinates, scaling down to match the original array size
                local_x := (screen_x - sprite_x) / SCALE_FACTOR;

                -- flip_y reverses the row lookup so the sprite renders upside-down
                if flip_y = '1' then
                    local_y := ((height - 1) - (screen_y - sprite_y)) / SCALE_FACTOR;
                else
                    local_y := (screen_y - sprite_y) / SCALE_FACTOR;
                end if;

                -- Select the colors using the sprite we are rendering
                -- Addr is used to search thru the 1d array to find the pixel pallete data.
                -- cuz the data is actually 1d array and not a 2d array.
                -- so we do some math to emulate 2d indexing.
                case sprite_id is
                    when 0 =>
                        palette_index := SKELETRON_HEAD_DATA(addr);
                        color := SKELETRON_HEAD_PALETTE(palette_index);
                        addr := local_y * SKELETRON_HEAD_WIDTH + local_x;
                    when 1 =>
                        palette_index := SKELETRON_JAW_DATA(addr);
                        color := SKELETRON_JAW_PALETTE(palette_index);
                        addr := local_y * SKELETRON_JAW_WIDTH + local_x;
                    when 2 =>
                        palette_index := FLAPPY_BIRD_DATA(addr);
                        color := FLAPPY_BIRD_PALETTE(palette_index);
                        addr := local_y * FLAPPY_BIRD_WIDTH + local_x;
                    when 3 =>
                        palette_index := FULL_HEART_DATA(addr);
                        color := FULL_HEART_PALETTE(palette_index);
                        addr := local_y * FULL_HEART_WIDTH + local_x;
                    when 4 =>
                        palette_index := EMPTY_HEART_DATA(addr);
                        color := EMPTY_HEART_PALETTE(palette_index);
                        addr := local_y * EMPTY_HEART_WIDTH + local_x;
                    when 5 =>
                        palette_index := BLUE_BRICK_TILE_DATA(addr);
                        color := BLUE_BRICK_TILE_PALETTE(palette_index);
                        addr := local_y * BLUE_BRICK_TILE_WIDTH + local_x;
                    when 6 =>
                        palette_index := LASER_BEAM_WARNING_DATA(addr);
                        color := LASER_BEAM_WARNING_PALETTE(palette_index);
                        addr := local_y * LASER_BEAM_WARNING_WIDTH + local_x;
                    when 7 =>
                        palette_index := LASER_BEAM_DATA(addr);
                        color := LASER_BEAM_PALETTE(palette_index);
                        addr := local_y * LASER_BEAM_WIDTH + local_x;
                    when 8 =>
                        palette_index := L3SKULL_DATA(addr);
                        color := L3SKULL_PALETTE(palette_index);
                        addr := local_y * L3SKULL_WIDTH + local_x;
                    when 9 =>
                        palette_index := POWERUP_DATA(addr);
                        color := POWERUP_PALETTE(palette_index);
                        addr := local_y * POWERUP_WIDTH + local_x;
                    when 10 =>
                        palette_index := BONE_BODY_DATA(addr);
                        color := BONE_BODY_PALETTE(palette_index);
                        addr := local_y * BONE_BODY_WIDTH + local_x;
                    when 11 =>
                        palette_index := BONE_CAP_DATA(addr);
                        color := BONE_CAP_PALETTE(palette_index);
                        addr := local_y * BONE_CAP_WIDTH + local_x;
                    when 12 =>
                        palette_index := BONE_BODY_2_DATA(addr);
                        color := BONE_BODY_2_PALETTE(palette_index);
                        addr := local_y * BONE_BODY_2_WIDTH + local_x;
                    when 13 =>
                        palette_index := BONE_CAP_2_DATA(addr);
                        color := BONE_CAP_2_PALETTE(palette_index);
                        addr := local_y * BONE_CAP_2_WIDTH + local_x;
					when 14 =>
                        palette_index := DARK_BRICK_TILE_DATA(addr);
                        color := DARK_BRICK_TILE_PALETTE(palette_index);
                        addr := local_y * DARK_BRICK_TILE_WIDTH + local_x;
					when 15 =>
                        palette_index := BRICK_TILE_DATA(addr);
                        color := BRICK_TILE_PALETTE(palette_index);
						addr := local_y * BRICK_TILE_WIDTH + local_x;
                    when others =>
                        palette_index := SKELETRON_HEAD_DATA(addr);
                        color := SKELETRON_HEAD_PALETTE(palette_index);
                        addr := 0;
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