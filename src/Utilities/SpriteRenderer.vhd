library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.sprite_data_pkg.all;

entity SpriteRenderer is
    generic (
        SCALE_FACTOR : integer range 1 to 2 := 1;
        SPRITE_ID : integer range 0 to 64 := 0
    );
    port (
        clk : in std_logic;
        pixel_row    : in std_logic_vector(9 downto 0);
        pixel_column : in std_logic_vector(9 downto 0);
        start_x  : in std_logic_vector(10 downto 0);
        start_y  : in std_logic_vector(10 downto 0);
        flip_y  : in std_logic := '0';
        red   : out std_logic_vector(3 downto 0);
        green : out std_logic_vector(3 downto 0);
        blue  : out std_logic_vector(3 downto 0);
        transparent : out std_logic
    );
end entity;

architecture behavior of SpriteRenderer is

    signal sprite_x : integer range -512 to 1023; -- BOUND TO REDUCE RESOURCE USAGE.
    signal sprite_y : integer range -512 to 1023;

    type dimensions is record
        width : integer range 0 to 1024;
        height : integer range 0 to 1024;
    end record;

    function GET_DIMENSIONS return dimensions is
        variable width : integer range 0 to 1024;
        variable height : integer range 0 to 1024;
        variable return_value : dimensions;
    begin
        case (SPRITE_ID) is
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
            when 16 =>
                width := SKELETRON_FULL_WIDTH;
                height := SKELETRON_FULL_HEIGHT;
            when 17 =>
                width := SKELETRON_MAD_WIDTH;
                height := SKELETRON_MAD_HEIGHT;
            when others =>
                width := SKELETRON_HEAD_WIDTH;
                height := SKELETRON_HEAD_HEIGHT;
        end case;

        return_value.width := width;
        return_value.height := height;

        return return_value;
    end function;

    constant sprite_dimensions : dimensions := GET_DIMENSIONS;
    constant scaled_width : integer range 0 to 2048 := sprite_dimensions.width * SCALE_FACTOR;
    constant scaled_height : integer range 0 to 2048 := sprite_dimensions.height * SCALE_FACTOR;
begin
    -- use integers since we have width and height as integers and its easier to do math by
    -- just turning them all into integers than having convert them each time.
    -- in the future we MUST add some range constraints to reduce the amount of bits we use.
    -- Cuz these use soooo much resources and i think its cuz of these that the compile times are so long.
    
    sprite_x <= to_integer(unsigned(start_x));
    sprite_y <= to_integer(unsigned(start_y));

    -- Stage 1 get width and height of the sprite based on the sprite id
    -- Only need to do this at initialization per sprite.


    process(clk)
        variable screen_x : integer range 0 to 640;
        variable screen_y : integer range 0 to 480;
        variable local_x : integer range 0 to 640;
        variable local_y : integer range 0 to 480;
        variable addr : integer range 0 to 307199;
        variable palette_index : integer range 0 to 255;
        variable color : std_logic_vector(11 downto 0);
    begin

        if rising_edge(clk) then
            
            screen_x := to_integer(unsigned(pixel_column));
            screen_y := to_integer(unsigned(pixel_row));

            -- default black
            red   <= "0000";
            green <= "0000";
            blue  <= "0000";
            transparent <= '1';

            -- Check if the current pixel is within the scaled sprite's bounding box
            if screen_x >= sprite_x and
               screen_x < sprite_x + scaled_width and
               screen_y >= sprite_y and
               screen_y < sprite_y + scaled_height then

                -- Calculate the local pixel coordinates, scaling down to match the original array size
                local_x := (screen_x - sprite_x) / SCALE_FACTOR;

                -- flip_y reverses the row lookup so the sprite renders upside-down
                -- this looks ugly but since its a generic and we only really use * 2 and * 4 scaling
                -- using compile time constants is more efficient.
                -- Don't care about anything higher than times 4 scaling.
                if SCALE_FACTOR = 1 then
                    local_x := screen_x - sprite_x;
                    if flip_y = '1' then
                        local_y := (sprite_dimensions.height - 1) - (screen_y - sprite_y);
                    else
                        local_y := screen_y - sprite_y;
                    end if;
                elsif SCALE_FACTOR = 2 then
                    local_x := (screen_x - sprite_x) / 2;
                    if flip_y = '1' then
                        local_y := ((sprite_dimensions.height - 1) - (screen_y - sprite_y)) / 2;
                    else
                        local_y := (screen_y - sprite_y) / 2;
                    end if;
                else
                    local_x := (screen_x - sprite_x) / 4;
                    if flip_y = '1' then
                        local_y := ((sprite_dimensions.height - 1) - (screen_y - sprite_y)) / 4;
                    else
                        local_y := (screen_y - sprite_y) / 4;
                    end if;
                end if;

                -- Select the colors using the sprite we are rendering
                -- Addr is used to search thru the 1d array to find the pixel pallete data.
                -- cuz the data is actually 1d array and not a 2d array.
                -- so we do some math to emulate 2d indexing.
                case SPRITE_ID is
                    when 0 =>
                        addr := local_y * SKELETRON_HEAD_WIDTH + local_x;
                        palette_index := SKELETRON_HEAD_DATA(addr);
                        color := SKELETRON_HEAD_PALETTE(palette_index);
                    when 1 =>                        
                        addr := local_y * SKELETRON_JAW_WIDTH + local_x;
                        palette_index := SKELETRON_JAW_DATA(addr);
                        color := SKELETRON_JAW_PALETTE(palette_index);
                    when 2 =>
                        addr := local_y * FLAPPY_BIRD_WIDTH + local_x;
                        palette_index := FLAPPY_BIRD_DATA(addr);
                        color := FLAPPY_BIRD_PALETTE(palette_index);                        
                    when 3 =>
                        addr := local_y * FULL_HEART_WIDTH + local_x;
                        palette_index := FULL_HEART_DATA(addr);
                        color := FULL_HEART_PALETTE(palette_index);
                    when 4 =>
                        addr := local_y * EMPTY_HEART_WIDTH + local_x;
                        palette_index := EMPTY_HEART_DATA(addr);
                        color := EMPTY_HEART_PALETTE(palette_index);
                    when 5 =>
                        addr := local_y * BLUE_BRICK_TILE_WIDTH + local_x;
                        palette_index := BLUE_BRICK_TILE_DATA(addr);
                        color := BLUE_BRICK_TILE_PALETTE(palette_index);
                    when 6 =>
                        addr := local_y * LASER_BEAM_WARNING_WIDTH + local_x;
                        palette_index := LASER_BEAM_WARNING_DATA(addr);
                        color := LASER_BEAM_WARNING_PALETTE(palette_index);
                    when 7 =>
                        addr := local_y * LASER_BEAM_WIDTH + local_x;
                        palette_index := LASER_BEAM_DATA(addr);
                        color := LASER_BEAM_PALETTE(palette_index);
                    when 8 =>
                        addr := local_y * L3SKULL_WIDTH + local_x;
                        palette_index := L3SKULL_DATA(addr);
                        color := L3SKULL_PALETTE(palette_index);
                    when 9 =>
                        addr := local_y * POWERUP_WIDTH + local_x;
                        palette_index := POWERUP_DATA(addr);
                        color := POWERUP_PALETTE(palette_index);                    
                    when 10 =>
                        addr := local_y * BONE_BODY_WIDTH + local_x;
                        palette_index := BONE_BODY_DATA(addr);
                        color := BONE_BODY_PALETTE(palette_index);                        
                    when 11 =>
                        addr := local_y * BONE_CAP_WIDTH + local_x;
                        palette_index := BONE_CAP_DATA(addr);
                        color := BONE_CAP_PALETTE(palette_index);                        
                    when 12 =>
                        addr := local_y * BONE_BODY_2_WIDTH + local_x;
                        palette_index := BONE_BODY_2_DATA(addr);
                        color := BONE_BODY_2_PALETTE(palette_index);                        
                    when 13 =>
                        addr := local_y * BONE_CAP_2_WIDTH + local_x;
                        palette_index := BONE_CAP_2_DATA(addr);
                        color := BONE_CAP_2_PALETTE(palette_index);                        
					when 14 =>
                        addr := local_y * DARK_BRICK_TILE_WIDTH + local_x;
                        palette_index := DARK_BRICK_TILE_DATA(addr);
                        color := DARK_BRICK_TILE_PALETTE(palette_index);                        
					when 15 =>
                        addr := local_y * BRICK_TILE_WIDTH + local_x;
                        palette_index := BRICK_TILE_DATA(addr);
                        color := BRICK_TILE_PALETTE(palette_index);
                    when 16 => 
                        addr := local_y * SKELETRON_FULL_WIDTH + local_x;
                        palette_index := SKELETRON_FULL_DATA(addr);
                        color := SKELETRON_FULL_PALETTE(palette_index);                        
                    when 17 => 
                        addr := local_y * SKELETRON_MAD_WIDTH + local_x;
                        palette_index := SKELETRON_MAD_DATA(addr);
                        color := SKELETRON_MAD_PALETTE(palette_index);
                    when others =>
                        addr := local_y * SKELETRON_HEAD_WIDTH + local_x;
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