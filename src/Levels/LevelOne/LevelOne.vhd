library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity LevelOne is
    port (
        clk25Mhz : IN std_logic;
        mouse_left : IN std_logic;
        vert_sync : IN std_logic;
		SW : IN std_logic_vector(9 downto 0);
		KEY : IN std_logic_vector(3 DOWNTO 0);
        level_one_enable : IN std_logic;
        pixel_row, pixel_column	: IN std_logic_vector(9 DOWNTO 0);
        paused : IN std_logic;
        pipe_1_enabled, pipe_2_enabled : OUT std_logic;
        pipe_1_red, pipe_1_green, pipe_1_blue : OUT std_logic_vector(3 downto 0);
        pipe_2_red, pipe_2_green, pipe_2_blue : OUT std_logic_vector(3 downto 0);
        pipe_1_x_pos : OUT unsigned(10 downto 0);
        pipe_2_x_pos : OUT unsigned(10 downto 0);
        pipe_1_render, pipe_2_render : OUT std_logic
    );
end entity LevelOne;

architecture behavior of LevelOne is
    component Pipe is 
        generic (
            START_OFFSET : integer := 0
        );
        port (
            clk, vert_sync, mouse_left  : in std_logic;
            pixel_row, pixel_column     : in std_logic_vector(9 downto 0);
            red, green, blue            : out std_logic_vector(3 downto 0);
            height                      : in integer range 0 to 480; -- Height of the centre of the gap in the pipe
            gap                         : in integer range 0 to 480; -- This is the size of the gap in the pipe
            reset                       : in std_logic;
            end_reached                 : out std_logic;
            x_pos                       : out unsigned(10 downto 0);
            enabled                     : in std_logic;
            render                      : out std_logic
        );
    end component Pipe;

	component LFSR is
        port (
        clk : IN std_logic;
        reset : IN std_logic;
        enable : IN std_logic;
        random_out : OUT std_logic_vector(7 downto 0)
    );
    end component LFSR;

    -- Pipe 1 Values
    signal pipe_1_enabled_s : std_logic := '0';
    signal pipe_1_end_reached : std_logic;
    signal pipe_1_x_pos_s : unsigned(10 downto 0);
    signal pipe_1_red_s, pipe_1_green_s, pipe_1_blue_s : std_logic_vector(3 downto 0);
    signal pipe_1_reset : std_logic := '0';
    signal pipe_1_height   : integer range 0 to 480 := 240;

    -- Pipe 2 Values
    signal pipe_2_enabled_s : std_logic := '0';
    signal pipe_2_end_reached : std_logic;
    signal pipe_2_x_pos_s : unsigned(10 downto 0);
    signal pipe_2_red_s, pipe_2_green_s, pipe_2_blue_s : std_logic_vector(3 downto 0);
    signal pipe_2_reset : std_logic := '0';
    signal pipe_2_height   : integer range 0 to 480 := 240;
    signal pipe_2_waiting : std_logic := '0';

    signal last_key_3_state : std_logic := '1';

    signal pipe_1_render_s : std_logic;
    signal pipe_2_render_s : std_logic;

    --LSFR
    signal lfsr_out      : std_logic_vector(7 downto 0);

begin
    pipe_1_enabled_s <= level_one_enable and not paused;
    
    PIPE_COMPONENT : Pipe
        generic map ( START_OFFSET => 0 )
        port map (
        clk => clk25Mhz,
        vert_sync => vert_sync,
        mouse_left => mouse_left,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        red => pipe_1_red_s,
        green => pipe_1_green_s,
        blue => pipe_1_blue_s,
        height => pipe_1_height,
        gap => 100,
        reset => pipe_1_reset,
        end_reached => pipe_1_end_reached,
        enabled => pipe_1_enabled_s,
        x_pos => pipe_1_x_pos_s,
        render => pipe_1_render_s
    );

    PIPE2_COMPONENT : Pipe
        generic map ( START_OFFSET => 200 )
        port map (
        clk => clk25Mhz,
        vert_sync => vert_sync,
        mouse_left => mouse_left,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        red => pipe_2_red_s,
        green => pipe_2_green_s,
        blue => pipe_2_blue_s,
        height => pipe_2_height,
        gap => 150,
        reset => pipe_2_reset,
        end_reached => pipe_2_end_reached,
        enabled => pipe_2_enabled_s,
        x_pos => pipe_2_x_pos_s,
        render => pipe_2_render_s
    );

    LFSR_COMPONENT : LFSR port map (
        clk        => clk25Mhz,
        reset      => '0',
        enable     => '1',
        random_out => lfsr_out
    );

    PIPE_HEIGHT_RANDOMISER : process (vert_sync)
    begin
        if rising_edge(vert_sync) then
            if level_one_enable = '1' then
                pipe_1_reset <= '0';
                if pipe_1_end_reached = '1' then
                    pipe_1_height <= to_integer(unsigned(lfsr_out)) * 280 / 256 + 100;
                    pipe_1_reset <= '1';
                end if;
            elsif (level_one_enable = '0') then
                pipe_1_reset <= '1'; -- Reset the pipe when the level is not enabled
            end if;
        end if;
    end process PIPE_HEIGHT_RANDOMISER;

    PIPE_2_HEIGHT_RANDOMISER : process (vert_sync)
    begin
        if rising_edge(vert_sync) then
            if level_one_enable = '1' then
					 if (pipe_1_x_pos_s = to_unsigned(320, 11)) then
						pipe_2_enabled_s <= level_one_enable and not paused; -- Spawn pipe 2 when pipe 1 reaches mid-screen
					 else
						pipe_2_enabled_s <= '0';
					 end if;
					 
                pipe_2_reset <= '0';
                if pipe_2_end_reached = '1' then
                    pipe_2_waiting <= '1';
                end if;

                -- Spawn pipe_2 when pipe_1 reaches mid-screen (consistent 320px spacing = 1/2 screen width)
                if (pipe_2_waiting = '1' and pipe_1_x_pos_s <= to_unsigned(320, 11)) then
                    pipe_2_height <= to_integer(unsigned(lfsr_out)) * 280 / 256 + 100;
                    pipe_2_reset <= '1';
                    pipe_2_waiting <= '0';
                end if;
            elsif (level_one_enable = '0') then
                pipe_2_reset <= '1'; -- Reset the pipe when the level is not enabled
                pipe_2_waiting <= '0';
            end if;
        end if;
    end process PIPE_2_HEIGHT_RANDOMISER;

    pipe_1_enabled <= pipe_1_enabled_s;
    pipe_2_enabled <= pipe_2_enabled_s;
    pipe_1_red <= pipe_1_red_s;
    pipe_1_green <= pipe_1_green_s;
    pipe_1_blue <= pipe_1_blue_s;
    pipe_2_red <= pipe_2_red_s;
    pipe_2_green <= pipe_2_green_s;
    pipe_2_blue <= pipe_2_blue_s;
    pipe_1_x_pos <= pipe_1_x_pos_s;
    pipe_2_x_pos <= pipe_2_x_pos_s;
    pipe_1_render <= pipe_1_render_s;
    pipe_2_render <= pipe_2_render_s;
end architecture behavior;