library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity TileRenderer is
    port (
        clk, vert_sync, mouse_left  : in std_logic;
        pixel_row, pixel_column     : in std_logic_vector(9 downto 0);
        red, green, blue            : out std_logic_vector(3 downto 0);
        reset                       : in std_logic;
        enabled                     : in std_logic;
        tile_id                     : in integer range 0 to 255;
		  transparent : out std_logic
    );
end entity TileRenderer;

architecture behaviour of TileRenderer is
    component SpriteRenderer is
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
    end component SpriteRenderer;

    signal sprite_red, sprite_green, sprite_blue : std_logic_vector(3 downto 0);
    signal sprite_transparent : std_logic;

    -- Tile metadata
    constant TILE_W : integer := 16;
    constant TILE_H : integer := 16;

    signal tile_start_x : std_logic_vector(9 downto 0);
    signal tile_start_y : std_logic_vector(9 downto 0);
begin
    tile_start_x <= std_logic_vector(
                        to_unsigned( (to_integer(unsigned(pixel_column)) / TILE_W) * TILE_W, 10)
                    );

    tile_start_y <= std_logic_vector(
                        to_unsigned( (to_integer(unsigned(pixel_row)) / TILE_H) * TILE_H, 10)
                    );

    SPRITE_RENDERER : SpriteRenderer port map (
        clk => clk,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => tile_start_x,
        start_y => tile_start_y,
        sprite_id => tile_id,  -- Use the provided tile_id
        red => sprite_red,
        green => sprite_green,
        blue => sprite_blue,
        transparent => sprite_transparent
    );

    -- Output if enabled and not transparent
    red <= sprite_red;
    green <= sprite_green;
    blue <= sprite_blue;
    transparent <= sprite_transparent;
end architecture behaviour;