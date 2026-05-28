library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity BossRenderer is
  port (
    clk25Mhz : IN std_logic;
    pixel_row, pixel_column : IN std_logic_vector(9 downto 0);
    red, green, blue : OUT std_logic_vector(3 downto 0);
    vert_sync : IN std_logic;
    enabled : OUT std_logic;
    x_pos : IN std_logic_vector(9 downto 0);
    y_pos : IN std_logic_vector(9 downto 0)
  );
end BossRenderer;

architecture behavior of BossRenderer is
    component SpriteRenderer is
        port (
            clk : in std_logic;
            pixel_row : in std_logic_vector(9 downto 0);
            pixel_column : in std_logic_vector(9 downto 0);
			start_x  : in std_logic_vector(10 downto 0);
			start_y  : in std_logic_vector(10 downto 0);
			sprite_id : in integer range 0 to 64;
            flip_y  : in std_logic := '0';
            tile_y  : in std_logic := '0';
            red : out std_logic_vector(3 downto 0);
            green : out std_logic_vector(3 downto 0);
            blue : out std_logic_vector(3 downto 0);
            transparent : out std_logic
        );
    end component;
    
    signal red_upper_jaw, green_upper_jaw, blue_upper_jaw : std_logic_vector(3 downto 0) := (others => '1');
    signal red_lower_jaw, green_lower_jaw, blue_lower_jaw : std_logic_vector(3 downto 0) := (others => '1');
    signal transparent_upper_jaw, transparent_lower_jaw : std_logic := '0';

    signal lower_jaw_x_offset : std_logic_vector(9 downto 0) := CONV_STD_LOGIC_VECTOR(13, 10); -- Adjust as needed for jaw positioning
    signal lower_jaw_y_offset : std_logic_vector(9 downto 0) := CONV_STD_LOGIC_VECTOR(57, 10); -- Adjust as needed for jaw positioning

    constant lower_jaw_anim_threshold : integer := 12; -- Number of clock cycles for lower jaw animation
begin
    BOSS_UPPER_JAW : SpriteRenderer port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => '0' & x_pos,
        start_y => '0' & y_pos,
        sprite_id => 0, -- Assuming 0 is the ID for the boss sprite
        flip_y => '0',
        tile_y => '0',
        red => red_upper_jaw,
        green => green_upper_jaw,
        blue => blue_upper_jaw,
        transparent => transparent_upper_jaw
    );

    BOSS_LOWER_JAW : SpriteRenderer port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => '0' & x_pos + lower_jaw_x_offset, -- Adjust x position for lower jaw
        start_y => '0' & y_pos + lower_jaw_y_offset, -- Adjust y position for lower jaw
        sprite_id => 1, -- Assuming 1 is the ID for the boss lower jaw sprite
        flip_y => '0',
        tile_y => '0',
        red => red_lower_jaw,
        green => green_lower_jaw,
        blue => blue_lower_jaw,
        transparent => transparent_lower_jaw
    );

    process (vert_sync)
        variable lower_jaw_anim_counter : integer range 0 to 24 := 0;
        variable moving_down : boolean := true;
    begin
        if rising_edge(vert_sync) then
            if moving_down then
                lower_jaw_y_offset <= lower_jaw_y_offset + 1;
            else
                lower_jaw_y_offset <= lower_jaw_y_offset - 1;
            end if;

            if lower_jaw_anim_counter = lower_jaw_anim_threshold then
                moving_down := not moving_down;
                lower_jaw_anim_counter := 0;
            else
                lower_jaw_anim_counter := lower_jaw_anim_counter + 1;
            end if;
        end if;
    end process;

    -- Combine upper and lower jaw outputs
    process (red_upper_jaw, green_upper_jaw, blue_upper_jaw, 
            transparent_upper_jaw, red_lower_jaw, green_lower_jaw,
            blue_lower_jaw, transparent_lower_jaw)
    begin
        if (transparent_upper_jaw = '0') then
            red <= red_upper_jaw;
            green <= green_upper_jaw;
            blue <= blue_upper_jaw;
            enabled <= '1';
        elsif (transparent_lower_jaw = '0') then
            red <= red_lower_jaw;
            green <= green_lower_jaw;
            blue <= blue_lower_jaw;
            enabled <= '1';
        else
            red <= (others => '0');
            green <= (others => '0');
            blue <= (others => '0');
            enabled <= '0';
        end if;
    end process;
end architecture behavior;