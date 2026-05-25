library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity Skull is 
    port (
        clk, vert_sync              : in std_logic;
        pixel_row, pixel_column     : in std_logic_vector(9 downto 0);
        red, green, blue            : out std_logic_vector(3 downto 0);
        spawn_y_pos                 : in integer range 0 to 480; -- Height of the skull's spawn
        reset                       : in std_logic;
        end_reached                 : out std_logic;
        x_pos                       : out unsigned(10 downto 0);
        enabled                     : in std_logic;
        render                      : out std_logic
    );
end entity Skull;

architecture behaviour of Skull is
    constant SCREEN_WIDTH  : integer := 640;
    constant SCREEN_HEIGHT : integer := 480;
    constant SKULL_WIDTH   : integer := 26;
    constant SKULL_HEIGHT  : integer := 28;
    constant SPEED         : integer := 2;

    signal skull_x_pos : unsigned(10 downto 0) := to_unsigned(SCREEN_WIDTH, 11); -- Start offscreen right
    signal skull_y_pos : integer range 0 to 480 := 0;

    signal render_s : std_logic;
    signal red_s, green_s, blue_s : std_logic_vector(3 downto 0);
    signal transparent : std_logic;

	component SpriteRenderer is
		port (
			clk : in std_logic;

			pixel_row    : in std_logic_vector(9 downto 0);
			pixel_column : in std_logic_vector(9 downto 0);

			start_x  : in std_logic_vector(10 downto 0);
			start_y  : in std_logic_vector(10 downto 0);
         sprite_id : in integer range 0 to 7;

			red   : out std_logic_vector(3 downto 0);
			green : out std_logic_vector(3 downto 0);
			blue  : out std_logic_vector(3 downto 0);

            transparent : out std_logic
		 );
	end component;

begin
    render_s <= '1' when (
        unsigned(pixel_column) >= skull_x_pos and
        unsigned(pixel_column) < skull_x_pos + to_unsigned(SKULL_WIDTH, 11) and
        unsigned(pixel_row) >= to_unsigned(skull_y_pos, 10) and
        unsigned(pixel_row) < to_unsigned(skull_y_pos + SKULL_HEIGHT, 10)
    ) else '0';

    SPRITE_RENDERER : SpriteRenderer port map (
        clk => clk,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => std_logic_vector(skull_x_pos),
        start_y      => '0' & std_logic_vector(to_unsigned(skull_y_pos, 10)),
        sprite_id => 6,
        red => red_s,
        blue => blue_s,
        green => green_s,
        transparent => transparent
    );

    SKULL_CONTROLLER : process (vert_sync)
    begin
        if rising_edge(vert_sync) then
            if reset = '1' then
                skull_x_pos <= to_unsigned(SCREEN_WIDTH, 11); -- Reset back to right edge off screen 
                skull_y_pos <= spawn_y_pos;
                end_reached <= '0';
            elsif enabled = '1' then
                if skull_x_pos <= to_unsigned(0, 11) then -- Reached left end
                    end_reached <= '1';
                    skull_x_pos <= to_unsigned(640, 11); -- respawn immediately to avoid visible hang at edge

                    -- Check if spawn_y_pos is too big (clamp)
                    if skull_y_pos > SCREEN_HEIGHT - SKULL_HEIGHT then
                        skull_y_pos <= SCREEN_HEIGHT - SKULL_HEIGHT;
                    end if;

                else
                    skull_x_pos <= skull_x_pos - to_unsigned(SPEED, 11); -- Move left
                    end_reached <= '0';
                end if;
            else
                null;
            end if;
        end if;
    end process SKULL_CONTROLLER;

    render <= render_s and not transparent; -- expose render signal
    red <= red_s;
    green <= green_s;
    blue <= blue_s;
    x_pos <= skull_x_pos;
end architecture behaviour;