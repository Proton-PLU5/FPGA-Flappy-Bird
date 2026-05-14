library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity BossRenderer is
  port (
    clk25Mhz : IN std_logic;
    pixel_row, pixel_column : IN std_logic_vector(9 downto 0);
    red, green, blue : OUT std_logic_vector(3 downto 0);
    enabled : OUT std_logic
  );
end BossRenderer;

architecture behavior of BossRenderer is
    component SpriteRenderer is
        port (
            clk : in std_logic;
            pixel_row : in std_logic_vector(9 downto 0);
            pixel_column : in std_logic_vector(9 downto 0);
            start_x : in std_logic_vector(9 downto 0);
            start_y : in std_logic_vector(9 downto 0);
            sprite_id : in integer;
            red : out std_logic_vector(3 downto 0);
            green : out std_logic_vector(3 downto 0);
            blue : out std_logic_vector(3 downto 0);
            transparent : out std_logic
        );
    end component;
    
    signal red_upper_jaw, green_upper_jaw, blue_upper_jaw : std_logic_vector(3 downto 0) := (others => '1');
    signal red_lower_jaw, green_lower_jaw, blue_lower_jaw : std_logic_vector(3 downto 0) := (others => '1');
    signal transparent_upper_jaw, transparent_lower_jaw : std_logic := '0';

    signal x_pos, y_pos : std_logic_vector(9 downto 0) := (others => '0');
    signal lower_jaw_x_offset, lower_jaw_y_offset : std_logic_vector(9 downto 0) := (others => '0'); -- Adjust as needed for jaw positioning

    constant lower_jaw_anim_threshold : integer := 50; -- Number of clock cycles for lower jaw animation
begin
    BOSS_UPPER_JAW : SpriteRenderer port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => x_pos,
        start_y => y_pos,
        sprite_id => 0, -- Assuming 0 is the ID for the boss sprite
        red => red_upper_jaw,
        green => green_upper_jaw,
        blue => blue_upper_jaw,
        transparent => transparent_upper_jaw
    );

    BOSS_LOWER_JAW : SpriteRenderer port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => x_pos + lower_jaw_x_offset, -- Adjust x position for lower jaw
        start_y => y_pos + lower_jaw_y_offset, -- Adjust y position for lower jaw
        sprite_id => 1, -- Assuming 1 is the ID for the boss lower jaw sprite
        red => red_lower_jaw,
        green => green_lower_jaw,
        blue => blue_lower_jaw,
        transparent => transparent_lower_jaw
    );


    x_pos <= CONV_STD_LOGIC_VECTOR(200, 10); -- Starting X position of the boss
    y_pos <= CONV_STD_LOGIC_VECTOR(100, 10); -- Starting Y position of the boss

    process (clk25Mhz)
        variable lower_jaw_anim_counter : integer range 0 to 99 := 0;
    begin
        if rising_edge(clk25Mhz) then
            if (lower_jaw_anim_counter < lower_jaw_anim_threshold) then
                lower_jaw_y_offset := lower_jaw_y_offset + 1;
            else
                lower_jaw_y_offset := lower_jaw_y_offset - 1;
            end if;
            
            lower_jaw_anim_counter := lower_jaw_anim_counter + 1;
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