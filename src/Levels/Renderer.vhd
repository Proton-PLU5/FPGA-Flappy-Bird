library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Renderer is
    port (
        clk25Mhz : IN std_logic;
        mouse_left : IN std_logic;
        vert_sync, horz_sync : IN std_logic;
        SW : IN std_logic_vector(9 downto 0);
        KEY : IN std_logic_vector(3 DOWNTO 0);
        pixel_row, pixel_column : IN std_logic_vector(9 DOWNTO 0);
        red, green, blue : OUT std_logic_vector(3 downto 0)
    );
end entity Renderer;

architecture behaviour of Renderer is
    component GameRenderer is
        port (
            clk25Mhz : IN std_logic;
            mouse_left : IN std_logic;
            vert_sync, horz_sync : IN std_logic;
            SW : in std_logic_vector(9 downto 0);
            KEY : IN std_logic_vector(3 DOWNTO 0);
            pixel_row, pixel_column : IN std_logic_vector(9 DOWNTO 0);
            red, green, blue : OUT std_logic_vector(3 downto 0);
            request_back : OUT std_logic;
            enabled : IN std_logic;
            game_over : OUT std_logic;
            score_out   : OUT integer range 0 to 999
        );
    end component GameRenderer;

    component TitleRenderer is
        port (
            clk25Mhz : IN std_logic;
            mouse_left : IN std_logic;
            vert_sync, horz_sync : IN std_logic;
            SW : in std_logic_vector(9 downto 0);
            KEY : IN std_logic_vector(3 DOWNTO 0);
            pixel_row, pixel_column : IN std_logic_vector(9 DOWNTO 0);
            red, green, blue : OUT std_logic_vector(3 downto 0);
            selected_mode : OUT integer range 0 to 2;
            proceed : OUT std_logic;
            enabled : IN std_logic
        );
    end component TitleRenderer;

    component GameOverRenderer is
        port (
            clk25Mhz : IN std_logic;
            mouse_left : IN std_logic;
            vert_sync, horz_sync : IN std_logic;
            pixel_row, pixel_column : IN std_logic_vector(9 DOWNTO 0);
            red, green, blue : OUT std_logic_vector(3 downto 0);
            request_back : OUT std_logic;
            enabled : IN std_logic
        );
    end component GameOverRenderer;

    signal red_play, green_play, blue_play : std_logic_vector(3 downto 0);
    signal red_title, green_title, blue_title : std_logic_vector(3 downto 0);

    -- Game Over signals
    signal red_gameover, green_gameover, blue_gameover : std_logic_vector(3 downto 0);
    signal game_over_s : std_logic := '0';
	 signal gameover_request_back : std_logic := '0';

    -- FSM control signals
    signal title_selected_mode : integer range 0 to 2 := 0; -- 0 for training, 1 for play, 2 for settings
    signal title_proceed : std_logic := '0'; -- Signal to indicate user wants to proceed from title screen
    signal game_request_back : std_logic := '0'; -- Signal from GameRenderer to request going back to title screen
    signal fsm_state : integer range 0 to 3 := 0; -- 0 for title, 1 for game, 2 for gameover, 3 for settings (if implemented)
	 
    -- Screen signals
    signal game_enabled : std_logic := '0';
    signal title_enabled : std_logic := '0';
    signal gameover_enabled : std_logic := '0';

    signal current_game_score  : integer range 0 to 999 := 0;

    -- Dummy signals to map unused level enable outputs
    signal level_one_enable, level_two_enable, level_three_enable, level_four_enable : std_logic;
begin

    GAME_RENDERER_COMPONENT : GameRenderer port map (
        clk25Mhz         => clk25Mhz,
        mouse_left       => mouse_left,
        vert_sync        => vert_sync,
        horz_sync        => horz_sync,
        SW               => SW,
        KEY              => KEY,
        pixel_row        => pixel_row,
        pixel_column     => pixel_column,
        red              => red_play,
        green            => green_play,
        blue             => blue_play,
        request_back     => game_request_back,
        enabled          => game_enabled,
        game_over        => game_over_s,
        score_out        => current_game_score  -- Exposing score to control path
    );

    TITLE_RENDERER_COMPONENT : TitleRenderer port map (
        clk25Mhz => clk25Mhz,
        mouse_left => mouse_left,
        vert_sync => vert_sync,
        horz_sync => horz_sync,
        SW => SW,
        KEY => KEY,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        red => red_title,
        green => green_title,
        blue => blue_title,
        selected_mode => title_selected_mode,
        proceed => title_proceed,
        enabled => title_enabled
    );
    
    GAMEOVER_RENDERER_COMPONENT : GameOverRenderer port map (
        clk25Mhz => clk25Mhz,
        mouse_left => mouse_left,
        vert_sync => vert_sync,
        horz_sync => horz_sync,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        red => red_gameover,
        green => green_gameover,
        blue => blue_gameover,
        request_back => gameover_request_back,
        enabled => gameover_enabled
    );
    
    -- FSM
    process(clk25Mhz)
    begin
        if rising_edge(clk25Mhz) then
            case fsm_state is
                when 0 => -- Title screen
                    if title_proceed = '1' and title_selected_mode = 1 then
                        fsm_state <= 1; -- Move to game screen
                    end if;

                    red <= red_title;
                    green <= green_title;
                    blue <= blue_title;

                    game_enabled <= '0';
                    title_enabled <= '1';
                    gameover_enabled <= '0';
                when 1 => -- Game screen
                    if game_request_back = '1' then
                        fsm_state <= 0; -- Move back to title screen
                    end if;

                    if game_over_s = '1' then
                        fsm_state <= 2; -- Move to game over screen
                    end if;

                    red <= red_play;
                    green <= green_play;
                    blue <= blue_play;

                    game_enabled <= '1';
                    title_enabled <= '0';
                    gameover_enabled <= '0';

                when 2 => -- Game Over screen
                    if gameover_request_back = '1' then
                        fsm_state <= 0; -- Move back to title screen
                    end if;

                    red <= red_gameover;
                    green <= green_gameover;
                    blue <= blue_gameover;

                    game_enabled <= '0';
                    title_enabled <= '0';
                    gameover_enabled <= '1';
                when others =>
                    fsm_state <= 0; -- Default back to title screen
            end case;
        end if;
    end process;

end architecture behaviour;