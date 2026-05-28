library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity PowerUp is
    port (
        clk, vert_sync, mouse_left  : in std_logic;
        pixel_row, pixel_column     : in std_logic_vector(9 downto 0);
        red, green, blue            : out std_logic_vector(3 downto 0);
        reset                       : in std_logic;
        collect                     : in std_logic;
        collect_count               : out integer;
        render                      : out std_logic;
        x_pos                       : out unsigned(10 downto 0);
        y_pos                       : out unsigned(9 downto 0);
        enable                      : in std_logic
    );
end entity PowerUp;

architecture behaviour of PowerUp is
    constant SCREEN_WIDTH  : integer := 640;
    constant SCREEN_HEIGHT  : integer := 480;
    constant POWERUP_WIDTH   : integer := 22;
    constant POWERUP_HEIGHT : integer := 24;
    constant SPEED          : integer := 8;
    constant COOLDOWN_MAX   : integer := 180;

    signal powerup_x_pos : unsigned(10 downto 0) := to_unsigned(SCREEN_WIDTH, 11);
    signal powerup_y_pos : unsigned(9 downto 0) := to_unsigned(0, 10);
    signal active : std_logic := '0';
    signal cooldown : integer range 0 to COOLDOWN_MAX := COOLDOWN_MAX;
    signal collect_count_s : integer := 0;

    signal lfsr : std_logic_vector(7 downto 0) := x"A5";
    signal render_s : std_logic;
    signal red_s, green_s, blue_s : std_logic_vector(3 downto 0);
    signal transparent : std_logic;

	component SpriteRenderer is
        generic (
            SCALE_FACTOR : integer := 1
        );
        port (
            clk : in std_logic;
            pixel_row : in std_logic_vector(9 downto 0);
            pixel_column : in std_logic_vector(9 downto 0);
            start_x  : in std_logic_vector(10 downto 0);
            start_y  : in std_logic_vector(10 downto 0);
            sprite_id : in integer range 0 to 64;
            red : out std_logic_vector(3 downto 0);
            green : out std_logic_vector(3 downto 0);
            blue : out std_logic_vector(3 downto 0);
            transparent : out std_logic
        );
    end component;
begin
    render_s <= '1' when (
        active = '1' and
        unsigned(pixel_column) >= powerup_x_pos and
        unsigned(pixel_column) < powerup_x_pos + to_unsigned(POWERUP_WIDTH, 11) and
        unsigned(pixel_row) >= powerup_y_pos and
        unsigned(pixel_row) < powerup_y_pos + to_unsigned(POWERUP_HEIGHT, 10)
    ) else '0';

    SPRITE_RENDERER : SpriteRenderer port map (
        clk => clk,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => std_logic_vector(powerup_x_pos),
        start_y      => '0' & std_logic_vector(powerup_y_pos),
        sprite_id => 9,
        red => red_s,
        blue => blue_s,
        green => green_s,
        transparent => transparent
    );

    -- Small 8-bit LFSR for occasional spawn positions.
    process (clk)
        variable feedback : std_logic;
    begin
        if rising_edge(clk) then
            feedback := lfsr(7) xor lfsr(5) xor lfsr(4) xor lfsr(3);
            lfsr <= lfsr(6 downto 0) & feedback;
        end if;
    end process;

    process (vert_sync)
        variable spawn_y : integer;
    begin
        if rising_edge(vert_sync) then
            if enable = '0' or reset = '1' then
                powerup_x_pos <= to_unsigned(SCREEN_WIDTH, 11);
                powerup_y_pos <= to_unsigned(0, 10);
                active <= '0';
                cooldown <= COOLDOWN_MAX;
            elsif collect = '1' then
                -- Item collected successfully! Despawn instantly and reset gate
                active <= '0';
                powerup_x_pos <= to_unsigned(SCREEN_WIDTH, 11);
                cooldown <= COOLDOWN_MAX;
            elsif active = '1' then
                if (powerup_x_pos + to_unsigned(POWERUP_WIDTH, 11)) <= to_unsigned(SPEED, 11) then
                    active <= '0';
                    powerup_x_pos <= to_unsigned(SCREEN_WIDTH, 11);
                    cooldown <= COOLDOWN_MAX;
                else
                    powerup_x_pos <= powerup_x_pos - to_unsigned(SPEED, 11);
                end if;
            elsif cooldown = 0 then
                spawn_y := to_integer(unsigned(lfsr)) * (SCREEN_HEIGHT - POWERUP_HEIGHT);
                spawn_y := spawn_y / 255;
                if spawn_y > SCREEN_HEIGHT - POWERUP_HEIGHT then
                    spawn_y := SCREEN_HEIGHT - POWERUP_HEIGHT - 50;
                end if;
                if spawn_y < 0 then
                    spawn_y := 50;
                end if;
                powerup_y_pos <= to_unsigned(spawn_y, 10);
                powerup_x_pos <= to_unsigned(SCREEN_WIDTH, 11);
                active <= '1';
            else
                cooldown <= cooldown - 1;
            end if;
        end if;
    end process;

    render <= render_s and not transparent; -- expose render signal
    red <= red_s;
    green <= green_s;
    blue <= blue_s;
    x_pos <= powerup_x_pos;
    y_pos <= powerup_y_pos;
    collect_count <= collect_count_s;
end architecture behaviour;