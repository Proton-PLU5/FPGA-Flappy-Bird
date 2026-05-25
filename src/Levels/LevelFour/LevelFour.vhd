library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity LevelFour is
    port (
        clk25Mhz : IN std_logic;
        mouse_left : IN std_logic;
        vert_sync : IN std_logic;
		SW : IN std_logic_vector(9 downto 0);
		KEY : IN std_logic_vector(3 DOWNTO 0);
        level_four_enable : IN std_logic;
        pixel_row, pixel_column	: IN std_logic_vector(9 DOWNTO 0);
        paused : IN std_logic;
    );
end entity LevelFour;

architecture behavior of LevelFour is
    component BossRenderer is
        port (
            clk25Mhz : IN std_logic;
            pixel_row, pixel_column : IN std_logic_vector(9 downto 0);
            red, green, blue : OUT std_logic_vector(3 downto 0);
            vert_sync : IN std_logic;
            enabled : OUT std_logic
        );
    end component BossRenderer;

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

    signal boss_red, boss_green, boss_blue : std_logic_vector(3 downto 0);
    signal boss_enabled : std_logic;

    -- LASER WARNING SIGNALS
    signal laser_warning_red, laser_warning_green, laser_warning_blue : std_logic_vector(3 downto 0);
    signal laser_warning_transparent : std_logic;
    signal laser_warning_enabled : std_logic;
    signal laser_warning_counter : integer range 0 to 100 := 0; -- Counter to control how long the warning is displayed

    -- LASER SIGNALS
    signal laser_red, laser_green, laser_blue : std_logic_vector(3 downto 0);
    signal laser_transparent : std_logic;
    signal laser_enabled : std_logic;
begin
    Boss: BossRenderer port map (
        clk25Mhz => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        red => boss_red,
        green => boss_green,
        blue => boss_blue,
        vert_sync => vert_sync,
        enabled => boss_enabled
    );

    LASER_WARNING : SpriteRenderer port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => CONV_STD_LOGIC_VECTOR(300, 10),
        start_y => CONV_STD_LOGIC_VECTOR(200, 10),
        sprite_id => 6, -- LASER_BEAM_WARNING
        red => laser_warning_red,
        green => laser_warning_green,
        blue => laser_warning_blue,
        transparent => laser_warning_transparent
    );

    LASER : SpriteRenderer port map (
        clk => clk25Mhz,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => CONV_STD_LOGIC_VECTOR(300, 10),
        start_y => CONV_STD_LOGIC_VECTOR(200, 10),
        sprite_id => 7, -- LASER_BEAM
        red => laser_red,
        green => laser_green,
        blue => laser_blue,
        transparent => laser_transparent
    );
    

    CLOCK_PROCESS : process(clk25Mhz)
    begin
        if rising_edge(clk25Mhz) then
        end if;
    end process;

    process (vert_sync)
    begin
        if rising_edge(vert_sync) then
            if (level_four_enable = '1') then
                if (laser_warning_counter < 100) then
                    laser_warning_enabled <= '1';
                    laser_warning_counter <= laser_warning_counter + 1;

                    laser_enabled <= '0'; -- Ensure laser is off while warning is displayed
                    laser_warning_enabled <= '1'; -- Show warning
                else
                    -- Display the laser
                    laser_enabled <= '1';
                    laser_warning_enabled <= '0';
                end if;
            end if;
        end if;
    end process;
    

end architecture behavior;