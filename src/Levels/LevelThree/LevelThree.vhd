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
        skull_1_enabled : OUT std_logic;
        skull_1_red, skull_1_green, skull_1_blue : OUT std_logic_vector(3 downto 0);
        skull_1_x_pos : OUT unsigned(10 downto 0);
        powerup_render : OUT std_logic;
        powerup_red, powerup_green, powerup_blue : OUT std_logic_vector(3 downto 0);
        powerup_collect : IN std_logic;
        powerup_count : OUT integer;
        skull_1_render : OUT std_logic
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

    constant SKULL_HEIGHT  : integer := 28;

    signal skull_1_render_s : std_logic := '0';
    signal skull_1_enabled_s : std_logic := '0';
    signal skull_1_end_reached : std_logic;
    signal skull_1_x_pos_s : unsigned(10 downto 0);
    signal skull_1_y_pos_s : integer range 0 to 480;
    signal skull_1_red_s, skull_1_green_s, skull_1_blue_s : std_logic_vector(3 downto 0);
    signal skull_1_reset : std_logic := '0';
    signal skull_1_height : integer range 0 to 480 := 240; -- Default height is 240

    signal powerup_render_s : std_logic := '0';
    signal powerup_red_s, powerup_green_s, powerup_blue_s : std_logic_vector(3 downto 0);
    signal powerup_reset : std_logic := '0';
    signal powerup_x_pos_s : unsigned(10 downto 0);
    signal powerup_y_pos_s : unsigned(9 downto 0);

    signal lfsr_out : std_logic_vector(7 downto 0);
begin
    skull_1_enabled_s <= level_three_enable and not paused;

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

    SKULL_RANDOMISER : process (vert_sync)
        variable random_y : integer;
    begin
        if rising_edge(vert_sync) then
            -- For duplicates, only enable once prev skull reaches 1/3 of screen x
            if skull_1_enabled_s = '1' then
                skull_1_reset <= '0';
                if skull_1_end_reached = '1' then
                    skull_1_y_pos_s <= (to_integer(unsigned(lfsr_out)) * (480 - SKULL_1_HEIGHT)) / 255; -- Create new y pos spawn
                    skull_1_reset <= '1';
                end if;
            elsif (level_three_enable = '0') then
                skull_1_reset <= '1'; -- Reset the skull when the level is not enabled
            end if;
        end if;
    end process SKULL_RANDOMISER;

    skull_1_enabled <= skull_1_enabled_s;
    skull_1_red <= skull_1_red_s;
    skull_1_green <= skull_1_green_s;
    skull_1_blue <= skull_1_blue_s;
    skull_1_x_pos <= skull_1_x_pos_s;
    skull_1_render <= skull_1_render_s;

    powerup_render <= powerup_render_s;
    powerup_red <= powerup_red_s;
    powerup_green <= powerup_green_s;
    powerup_blue <= powerup_blue_s;
end architecture behavior;