library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity LevelThree is
    port (
        clk25Mhz : IN std_logic;
        mouse_left : IN std_logic;
        vert_sync : IN std_logic;
        SW : IN std_logic_vector(9 downto 0);
        KEY : IN std_logic_vector(3 DOWNTO 0);
        level_three_enable : IN std_logic := '0';
        pixel_row, pixel_column	: IN std_logic_vector(9 DOWNTO 0);
        paused : IN std_logic;
        skull_1_enabled, skull_2_enabled, skull_3_enabled, skull_4_enabled, skull_5_enabled : OUT std_logic;
        skull_1_red, skull_1_green, skull_1_blue : OUT std_logic_vector(3 downto 0);
        skull_2_red, skull_2_green, skull_2_blue : OUT std_logic_vector(3 downto 0);
        skull_3_red, skull_3_green, skull_3_blue : OUT std_logic_vector(3 downto 0);
        skull_4_red, skull_4_green, skull_4_blue : OUT std_logic_vector(3 downto 0);
        skull_5_red, skull_5_green, skull_5_blue : OUT std_logic_vector(3 downto 0);
        skull_1_x_pos, skull_2_x_pos, skull_3_x_pos, skull_4_x_pos, skull_5_x_pos : OUT unsigned(10 downto 0);
        powerup_render : OUT std_logic;
        powerup_red, powerup_green, powerup_blue : OUT std_logic_vector(3 downto 0);
        powerup_collect : IN std_logic;
        powerup_count : OUT integer;
        skull_1_render, skull_2_render, skull_3_render, skull_4_render, skull_5_render : OUT std_logic
    );
end entity LevelThree;

architecture behavior of LevelThree is
    component Skull is 
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
    end component Skull;

    component PowerUp is
        port (
            clk, vert_sync, mouse_left : in std_logic;
            pixel_row, pixel_column : in std_logic_vector(9 downto 0);
            red, green, blue : out std_logic_vector(3 downto 0);
            reset : in std_logic;
            collect : in std_logic;
            collect_count : out integer;
            render : out std_logic;
            x_pos : out unsigned(10 downto 0);
            y_pos : out unsigned(9 downto 0);
            enable : in std_logic
        );
    end component PowerUp;

    component LFSR is
        port (
            clk : IN std_logic;
            reset : IN std_logic;
            enable : IN std_logic;
            random_out : OUT std_logic_vector(7 downto 0)
        );
    end component LFSR;

    constant SKULL_HEIGHT  : integer := 56;

    constant LANE_0 : integer := 40;
    constant LANE_1 : integer := 120;
    constant LANE_2 : integer := 200;
    constant LANE_3 : integer := 280;
    constant LANE_4 : integer := 360;

    signal skull_1_render_s : std_logic := '0';
    signal skull_1_enabled_s : std_logic := '0';
    signal skull_1_end_reached : std_logic;
    signal skull_1_x_pos_s : unsigned(10 downto 0);
    signal skull_1_y_pos_s : integer range 0 to 480;
    signal skull_1_red_s, skull_1_green_s, skull_1_blue_s : std_logic_vector(3 downto 0);
    signal skull_1_reset : std_logic := '0';
    signal skull_1_height : integer range 0 to 480 := 240; -- Default height is 240

    signal skull_2_render_s : std_logic := '0';
    signal skull_2_enabled_s : std_logic := '0';
    signal skull_2_end_reached : std_logic;
    signal skull_2_x_pos_s : unsigned(10 downto 0);
    signal skull_2_y_pos_s : integer range 0 to 480;
    signal skull_2_red_s, skull_2_green_s, skull_2_blue_s : std_logic_vector(3 downto 0);
    signal skull_2_reset : std_logic := '0';
    signal skull_2_height : integer range 0 to 480 := 240; -- Default height is 240
    signal skull_2_waiting : std_logic := '0';

    signal skull_3_render_s : std_logic := '0';
    signal skull_3_enabled_s : std_logic := '0';
    signal skull_3_end_reached : std_logic;
    signal skull_3_x_pos_s : unsigned(10 downto 0);
    signal skull_3_y_pos_s : integer range 0 to 480;
    signal skull_3_red_s, skull_3_green_s, skull_3_blue_s : std_logic_vector(3 downto 0);
    signal skull_3_reset : std_logic := '0';
    signal skull_3_height : integer range 0 to 480 := 240; -- Default height is 240
    signal skull_3_waiting : std_logic := '0';

    signal skull_4_render_s : std_logic := '0';
    signal skull_4_enabled_s : std_logic := '0';
    signal skull_4_end_reached : std_logic;
    signal skull_4_x_pos_s : unsigned(10 downto 0);
    signal skull_4_y_pos_s : integer range 0 to 480;
    signal skull_4_red_s, skull_4_green_s, skull_4_blue_s : std_logic_vector(3 downto 0);
    signal skull_4_reset : std_logic := '0';
    signal skull_4_height : integer range 0 to 480 := 240; -- Default height is 240
    signal skull_4_waiting : std_logic := '0';

    signal skull_5_render_s : std_logic := '0';
    signal skull_5_enabled_s : std_logic := '0';
    signal skull_5_end_reached : std_logic;
    signal skull_5_x_pos_s : unsigned(10 downto 0);
    signal skull_5_y_pos_s : integer range 0 to 480;
    signal skull_5_red_s, skull_5_green_s, skull_5_blue_s : std_logic_vector(3 downto 0);
    signal skull_5_reset : std_logic := '0';
    signal skull_5_height : integer range 0 to 480 := 240; -- Default height is 240
    signal skull_5_waiting : std_logic := '0';

    signal powerup_render_s : std_logic := '0';
    signal powerup_red_s, powerup_green_s, powerup_blue_s : std_logic_vector(3 downto 0);
    signal powerup_reset : std_logic := '0';
    signal powerup_x_pos_s : unsigned(10 downto 0);
    signal powerup_y_pos_s : unsigned(9 downto 0);

    signal lfsr_out : std_logic_vector(7 downto 0);
begin
    skull_1_enabled_s <= level_three_enable and not paused;
    skull_2_enabled_s <= level_three_enable and not paused;
    skull_3_enabled_s <= level_three_enable and not paused;
    skull_4_enabled_s <= level_three_enable and not paused;
    skull_5_enabled_s <= level_three_enable and not paused;

    SKULL_1_COMPONENT : Skull port map (
        clk => clk25Mhz,
        vert_sync => vert_sync,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        red => skull_1_red_s,
        green => skull_1_green_s,
        blue => skull_1_blue_s,
        spawn_y_pos => skull_1_y_pos_s,
        reset => skull_1_reset,
        end_reached => skull_1_end_reached,
        x_pos => skull_1_x_pos_s,
        enabled => skull_1_enabled_s,
        render => skull_1_render_s
    );

    SKULL_2_COMPONENT : Skull port map (
        clk => clk25Mhz,
        vert_sync => vert_sync,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        red => skull_2_red_s,
        green => skull_2_green_s,
        blue => skull_2_blue_s,
        spawn_y_pos => skull_2_y_pos_s,
        reset => skull_2_reset,
        end_reached => skull_2_end_reached,
        x_pos => skull_2_x_pos_s,
        enabled => skull_2_enabled_s,
        render => skull_2_render_s
    );

   SKULL_3_COMPONENT : Skull port map (
       clk => clk25Mhz,
       vert_sync => vert_sync,
       pixel_row => pixel_row,
       pixel_column => pixel_column,
       red => skull_3_red_s,
       green => skull_3_green_s,
       blue => skull_3_blue_s,
       spawn_y_pos => skull_3_y_pos_s,
       reset => skull_3_reset,
       end_reached => skull_3_end_reached,
       x_pos => skull_3_x_pos_s,
       enabled => skull_3_enabled_s,
       render => skull_3_render_s
   );

    SKULL_4_COMPONENT : Skull port map (
        clk => clk25Mhz,
        vert_sync => vert_sync,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        red => skull_4_red_s,
        green => skull_4_green_s,
        blue => skull_4_blue_s,
        spawn_y_pos => skull_4_y_pos_s,
        reset => skull_4_reset,
        end_reached => skull_4_end_reached,
        x_pos => skull_4_x_pos_s,
        enabled => skull_4_enabled_s,
        render => skull_4_render_s
    );

    SKULL_5_COMPONENT : Skull port map (
        clk => clk25Mhz,
        vert_sync => vert_sync,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        red => skull_5_red_s,
        green => skull_5_green_s,
        blue => skull_5_blue_s,
        spawn_y_pos => skull_5_y_pos_s,
        reset => skull_5_reset,
        end_reached => skull_5_end_reached,
        x_pos => skull_5_x_pos_s,
        enabled => skull_5_enabled_s,
        render => skull_5_render_s
    );

    POWERUP_COMPONENT : PowerUp port map (
        clk => clk25Mhz,
        vert_sync => vert_sync,
        mouse_left => mouse_left,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        red => powerup_red_s,
        green => powerup_green_s,
        blue => powerup_blue_s,
        reset => powerup_reset,
        collect => powerup_collect,
        collect_count => powerup_count,
        render => powerup_render_s,
        x_pos => powerup_x_pos_s,
        y_pos => powerup_y_pos_s,
        enable => level_three_enable
    );

    LFSR_COMPONENT : LFSR port map (
        clk => clk25Mhz,
        reset => '0',
        enable => '1',
        random_out => lfsr_out
    );

    --spawn_y_pos := to_integer(unsigned(lfsr)) * (SCREEN_HEIGHT - SKULL_SIZE);
    --spawn_y_pos := spawn_y_pos / 255;

    SKULL_1_RANDOMISER : process (vert_sync)
        variable random_y : integer;
        variable lane_sel : std_logic_vector(2 downto 0);
    begin
        if rising_edge(vert_sync) then
            if skull_1_enabled_s = '1' then
                skull_1_reset <= '0';
                if skull_1_end_reached = '1' then
                    lane_sel := lfsr_out(2 downto 0) xor std_logic_vector(to_unsigned(1, 3));

                    case lane_sel is
                        when "000" => skull_1_y_pos_s <= LANE_0;
                        when "001" => skull_1_y_pos_s <= LANE_1;
                        when "010" => skull_1_y_pos_s <= LANE_2;
                        when "011" => skull_1_y_pos_s <= LANE_3;
                        when others => skull_1_y_pos_s <= LANE_4;
                    end case;

                    skull_1_reset <= '1';
                end if;
            elsif (level_three_enable = '0') then
                skull_1_reset <= '1'; -- Reset the skull when the level is not enabled
            end if;
        end if;
    end process SKULL_1_RANDOMISER;

    SKULL_2_RANDOMISER : process (vert_sync)
        variable random_y : integer;
        variable lane_sel : std_logic_vector(2 downto 0);
    begin
        if rising_edge(vert_sync) then
            if skull_1_x_pos_s <= to_unsigned(640 / 5, skull_1_x_pos_s'length) then
                skull_2_waiting <= '1';
            end if;

            -- For duplicates, only enable once prev skull reaches 1/3 of screen x
            if skull_2_enabled_s = '1' and skull_2_waiting = '1' then
                skull_2_reset <= '0';
                if skull_2_end_reached = '1' then
                    lane_sel := lfsr_out(2 downto 0) xor std_logic_vector(to_unsigned(2, 3));

                    case lane_sel is
                        when "000" => skull_2_y_pos_s <= LANE_0;
                        when "001" => skull_2_y_pos_s <= LANE_1;
                        when "010" => skull_2_y_pos_s <= LANE_2;
                        when "011" => skull_2_y_pos_s <= LANE_3;
                        when others => skull_2_y_pos_s <= LANE_4;
                    end case;

                    skull_2_reset <= '1';
                end if;
            elsif (level_three_enable = '0') then
                skull_2_reset <= '1'; -- Reset the skull when the level is not enabled
            end if;
        end if;
    end process SKULL_2_RANDOMISER;

    SKULL_3_RANDOMISER : process (vert_sync)
        variable random_y : integer;
        variable lane_sel : std_logic_vector(2 downto 0);
    begin
        if rising_edge(vert_sync) then
            if skull_2_x_pos_s <= to_unsigned(640 / 5, skull_2_x_pos_s'length) then
                skull_3_waiting <= '1';
            end if;

            if skull_3_enabled_s = '1' and skull_3_waiting = '1' then
                skull_3_reset <= '0';
                if skull_3_end_reached = '1' then
                    lane_sel := lfsr_out(2 downto 0) xor std_logic_vector(to_unsigned(3, 3));

                    case lane_sel is
                        when "000" => skull_3_y_pos_s <= LANE_0;
                        when "001" => skull_3_y_pos_s <= LANE_1;
                        when "010" => skull_3_y_pos_s <= LANE_2;
                        when "011" => skull_3_y_pos_s <= LANE_3;
                        when others => skull_3_y_pos_s <= LANE_4;
                    end case;

                    skull_2_reset <= '1';
                end if;
            elsif (level_three_enable = '0') then
                skull_3_reset <= '1'; -- Reset the skull when the level is not enabled
            end if;
        end if;
    end process SKULL_3_RANDOMISER;

    SKULL_4_RANDOMISER : process (vert_sync)
        variable random_y : integer;
        variable lane_sel : std_logic_vector(2 downto 0);
    begin
        if rising_edge(vert_sync) then
            if skull_3_x_pos_s <= to_unsigned(640 / 5, skull_3_x_pos_s'length) then
                skull_4_waiting <= '1';
            end if;

            if skull_4_enabled_s = '1' and skull_4_waiting = '1' then
                skull_4_reset <= '0';
                if skull_4_end_reached = '1' then
                    lane_sel := lfsr_out(2 downto 0) xor std_logic_vector(to_unsigned(4, 3));

                    case lane_sel is
                        when "000" => skull_4_y_pos_s <= LANE_0;
                        when "001" => skull_4_y_pos_s <= LANE_1;
                        when "010" => skull_4_y_pos_s <= LANE_2;
                        when "011" => skull_4_y_pos_s <= LANE_3;
                        when others => skull_4_y_pos_s <= LANE_4;
                    end case;

                    skull_2_reset <= '1';
                end if;
            elsif (level_three_enable = '0') then
                skull_4_reset <= '1'; -- Reset the skull when the level is not enabled
            end if;
        end if;
    end process SKULL_4_RANDOMISER;

    SKULL_5_RANDOMISER : process (vert_sync)
        variable random_y : integer;
        variable lane_sel : std_logic_vector(2 downto 0);
    begin
        if rising_edge(vert_sync) then
            if skull_4_x_pos_s <= to_unsigned(640 / 5, skull_4_x_pos_s'length) then
                skull_5_waiting <= '1';
            end if;

            if skull_5_enabled_s = '1' and skull_5_waiting = '1' then
                skull_5_reset <= '0';
                if skull_5_end_reached = '1' then
                    lane_sel := lfsr_out(2 downto 0) xor std_logic_vector(to_unsigned(5, 3));

                    case lane_sel is
                        when "000" => skull_5_y_pos_s <= LANE_0;
                        when "001" => skull_5_y_pos_s <= LANE_1;
                        when "010" => skull_5_y_pos_s <= LANE_2;
                        when "011" => skull_5_y_pos_s <= LANE_3;
                        when others => skull_5_y_pos_s <= LANE_4;
                    end case;

                    skull_2_reset <= '1';
                end if;
            elsif (level_three_enable = '0') then
                skull_5_reset <= '1'; -- Reset the skull when the level is not enabled
            end if;
        end if;
    end process SKULL_5_RANDOMISER;

    skull_1_enabled <= skull_1_enabled_s;
    skull_1_red <= skull_1_red_s;
    skull_1_green <= skull_1_green_s;
    skull_1_blue <= skull_1_blue_s;
    skull_1_x_pos <= skull_1_x_pos_s;
    skull_1_render <= skull_1_render_s;

    skull_2_enabled <= skull_2_enabled_s;
    skull_2_red <= skull_2_red_s;
    skull_2_green <= skull_2_green_s;
    skull_2_blue <= skull_2_blue_s;
    skull_2_x_pos <= skull_2_x_pos_s;
    skull_2_render <= skull_2_render_s;

    skull_3_enabled <= skull_3_enabled_s;
    skull_3_red <= skull_3_red_s;
    skull_3_green <= skull_3_green_s;
    skull_3_blue <= skull_3_blue_s;
    skull_3_x_pos <= skull_3_x_pos_s;
    skull_3_render <= skull_3_render_s;

    skull_4_enabled <= skull_4_enabled_s;
    skull_4_red <= skull_4_red_s;
    skull_4_green <= skull_4_green_s;
    skull_4_blue <= skull_4_blue_s;
    skull_4_x_pos <= skull_4_x_pos_s;
    skull_4_render <= skull_4_render_s;

    skull_5_enabled <= skull_5_enabled_s;
    skull_5_red <= skull_5_red_s;
    skull_5_green <= skull_5_green_s;
    skull_5_blue <= skull_5_blue_s;
    skull_5_x_pos <= skull_5_x_pos_s;
    skull_5_render <= skull_5_render_s;

    powerup_render <= powerup_render_s;
    powerup_red <= powerup_red_s;
    powerup_green <= powerup_green_s;
    powerup_blue <= powerup_blue_s;
end architecture behavior;