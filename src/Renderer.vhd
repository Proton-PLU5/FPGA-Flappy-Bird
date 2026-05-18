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
            level_state : IN integer range 1 to 4;
            score_out   : OUT integer range 0 to 999;
            level_one_enable, level_two_enable, level_three_enable, level_four_enable : out std_logic
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
            start_game : OUT std_logic;
            enabled : IN std_logic
        );
    end component TitleRenderer;

    signal red_play, green_play, blue_play : std_logic_vector(3 downto 0);
    signal red_title, green_title, blue_title : std_logic_vector(3 downto 0);

    signal play_state : std_logic := '0';
    signal title_state : std_logic := '1';
    signal state : integer range 0 to 1 := 0; -- 0 for title, 1 for play

    signal title_start_game : std_logic := '0';
    signal game_request_back : std_logic := '0';
    
    -- Level tracking signals
    signal level_state_s : integer range 1 to 4 := 1;
    signal current_game_score  : integer range 0 to 999 := 0;

    -- Dummy signals to map unused level enable outputs
    signal l1_en, l2_en, l3_en, l4_en : std_logic;
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
        enabled          => play_state,
        level_state      => level_state_s, -- Control path driving data path
        score_out        => current_game_score,  -- Exposing score to control path
        level_one_enable => l1_en,
        level_two_enable => l2_en,
        level_three_enable => l3_en,
        level_four_enable => l4_en
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
        start_game => title_start_game,
        enabled => title_state
    );

    -- Centralized Game State Machine (Screens & Game Levels)
	 -- title_start_game and game_request_back take priority, then manual KEY overrides (KEY(2) -> play, KEY(3) -> title)
    process(clk25Mhz)
    begin
        if rising_edge(clk25Mhz) then
            -- Title to game routing logic
            if title_start_game = '1' then
                state <= 1; 
                level_state_s <= 1; -- Reset game to Level 1 on new start
            elsif game_request_back = '1' then
                state <= 0; 
            elsif KEY(2) = '0' then
                state <= 1;
                level_state_s <= 1;
            elsif KEY(3) = '0' then
                state <= 0;
            end if;

            -- Level transition logic (Only updates if currently in the play state)
            if state = 1 then
                if current_game_score > 10 then
                    level_state_s <= 2;
                end if;
            else
                level_state_s <= 1;
            end if;
        end if;
     end process;

    title_state <= '1' when state = 0 else '0';
    play_state  <= '1' when state = 1 else '0';

    red   <= red_play   WHEN play_state = '1' ELSE red_title;
    green <= green_play WHEN play_state = '1' ELSE green_title;
    blue  <= blue_play  WHEN play_state = '1' ELSE blue_title;

end architecture behaviour;