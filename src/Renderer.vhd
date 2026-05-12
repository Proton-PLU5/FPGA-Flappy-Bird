
entity Renderer is
    port (
        clk25Mhz : IN std_logic;
        mouse_left : IN std_logic;
        vert_sync, horz_sync : IN std_logic;
		  SW : IN std_logic_vector(9 downto 0);
		  KEY : IN std_logic_vector(3 DOWNTO 0);
        pixel_row, pixel_column	: IN std_logic_vector(9 DOWNTO 0);
        red, green, blue : OUT std_logic_vector(3 downto 0);
		  enabled : IN std_logic
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
			pixel_row, pixel_column	: IN std_logic_vector(9 DOWNTO 0);
			red, green, blue : OUT std_logic_vector(3 downto 0)
		);
	end component GameRenderer;

	component TitleRenderer is
		port (
			clk25Mhz : IN std_logic;
			mouse_left : IN std_logic;
			vert_sync, horz_sync : IN std_logic;
		   SW : in std_logic_vector(9 downto 0);
			KEY : IN std_logic_vector(3 DOWNTO 0);
			pixel_row, pixel_column	: IN std_logic_vector(9 DOWNTO 0);
			red, green, blue : OUT std_logic_vector(3 downto 0)
		);
	end component TitleRenderer;

    signal red_play, green_play, blue_play : std_logic_vector(3 downto 0);
	signal red_title, green_title, blue_title : std_logic_vector(3 downto 0);

    signal play_state : std_logic := '0';
	signal title_state : std_logic := '1';
	signal state : integer range 0 to 1 := 0; -- 0 for title, 1 for play
begin

    GAME_RENDERER_COMPONENT : GameRenderer port map (
		clk25Mhz => Clk25Mhz,
		mouse_left => left_button,
		vert_sync => vert_sync_out,
		horz_sync => horz_sync_out,
		SW => SW,
		KEY => KEY,
		pixel_row => pixel_row,
		pixel_column => pixel_column,
		red => red_play,
		green => green_play,
		blue => blue_play
        enabled => play_state
	);

	TITLE_RENDERER_COMPONENT : TitleRenderer port map (
		clk25Mhz => Clk25Mhz,
		mouse_left => left_button,
		vert_sync => vert_sync_out,
		horz_sync => horz_sync_out,
		SW => SW,
		KEY => KEY,
		pixel_row => pixel_row,
		pixel_column => pixel_column,
		red => red_title, -- We can ignore the title renderer's output for now
		green => green_title,
		blue => blue_title,
        enabled => title_state
	);

    state <= 0 when (key(3) = '0') else
             1 when (key(2) = '0') else
             state;

    title_state <= '1' when state = 0 else '0';
    play_state <= '1' when state = 1 else '0';

    red <= red_play WHEN play_state = '1' ELSE red_title;
    green <= green_play WHEN play_state = '1' ELSE green_title;
    blue <= blue_play WHEN play_state = '1' ELSE blue_title;
end architecture behaviour;