library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity BossRenderer is
  generic (
    SCALE_FACTOR : integer := 1
  );
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
        generic (
            SCALE_FACTOR : integer := 1;
            SPRITE_ID : integer range 0 to 64 := 0
        );
        port (
            clk : in std_logic;
            pixel_row : in std_logic_vector(9 downto 0);
            pixel_column : in std_logic_vector(9 downto 0);
			start_x  : in std_logic_vector(10 downto 0);
			start_y  : in std_logic_vector(10 downto 0);
            flip_y  : in std_logic := '0';
            red : out std_logic_vector(3 downto 0);
            green : out std_logic_vector(3 downto 0);
            blue : out std_logic_vector(3 downto 0);
            transparent : out std_logic
        );
    end component;
    
    signal red_upper_jaw, green_upper_jaw, blue_upper_jaw : std_logic_vector(3 downto 0) := (others => '1');
    signal red_lower_jaw, green_lower_jaw, blue_lower_jaw : std_logic_vector(3 downto 0) := (others => '1');
    signal transparent_upper_jaw, transparent_lower_jaw : std_logic := '0';

    constant lower_jaw_x_offset_base : integer := 13; -- Base jaw x offset in unscaled pixels
    constant lower_jaw_y_offset_base : integer := 57; -- Base jaw y offset in unscaled pixels

    constant lower_jaw_anim_step : std_logic_vector(9 downto 0) :=
        CONV_STD_LOGIC_VECTOR(SCALE_FACTOR, 10);

    signal lower_jaw_x_offset : std_logic_vector(9 downto 0) :=
        CONV_STD_LOGIC_VECTOR(lower_jaw_x_offset_base * SCALE_FACTOR, 10);
    signal lower_jaw_y_offset : std_logic_vector(9 downto 0) :=
        CONV_STD_LOGIC_VECTOR(lower_jaw_y_offset_base * SCALE_FACTOR, 10);

    constant lower_jaw_anim_threshold : integer := 12; -- Number of clock cycles for lower jaw animation

    signal upper_x_clocked : std_logic_vector(10 downto 0) := (others => '0');
    signal upper_y_clocked : std_logic_vector(10 downto 0) := (others => '0');
    signal lower_x_clocked : std_logic_vector(10 downto 0) := (others => '0');
    signal lower_y_clocked : std_logic_vector(10 downto 0) := (others => '0');
begin

    PIPELINE_COORDS : process(clk25Mhz)
    begin
        if rising_edge(clk25Mhz) then
            upper_x_clocked <= '0' & x_pos;
            upper_y_clocked <= '0' & y_pos;
            
            lower_x_clocked <= ('0' & x_pos) + lower_jaw_x_offset;
            lower_y_clocked <= ('0' & y_pos) + lower_jaw_y_offset;
        end if;
    end process PIPELINE_COORDS;

    BOSS_UPPER_JAW : SpriteRenderer 
    generic map (
        SCALE_FACTOR => SCALE_FACTOR,
        SPRITE_ID => 0
    )
    port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => upper_x_clocked,
        start_y => upper_y_clocked,
        flip_y => '0',
        red => red_upper_jaw,
        green => green_upper_jaw,
        blue => blue_upper_jaw,
        transparent => transparent_upper_jaw
    );

    BOSS_LOWER_JAW : SpriteRenderer 
    generic map (
        SCALE_FACTOR => SCALE_FACTOR,
        SPRITE_ID => 1
    )
    port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => lower_x_clocked,
        start_y => lower_y_clocked,
        flip_y => '0',
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
                lower_jaw_y_offset <= lower_jaw_y_offset + lower_jaw_anim_step;
            else
                lower_jaw_y_offset <= lower_jaw_y_offset - lower_jaw_anim_step;
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