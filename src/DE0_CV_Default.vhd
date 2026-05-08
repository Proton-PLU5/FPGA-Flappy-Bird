library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DE0_CV_Default is
    port (
        CLOCK_50 : in std_logic;
		  VGA_G, VGA_B, VGA_R : out std_logic_vector(3 downto 0);
		  VGA_HS : out std_logic;
		  VGA_VS : out std_logic;
		  PS2_DAT, PS2_CLK : INOUT std_logic
    );
end DE0_CV_Default;

architecture behavior of DE0_CV_Default is
    
    component VGA_SYNC
		PORT(	clock_25Mhz : IN	STD_LOGIC;
			red, green, blue: IN	STD_LOGIC_VECTOR(3 downto 0);
			red_out, green_out, blue_out : OUT STD_LOGIC_VECTOR(3 downto 0);
			horiz_sync_out, vert_sync_out	: OUT	STD_LOGIC;
			pixel_row, pixel_column: OUT STD_LOGIC_VECTOR(9 DOWNTO 0));
    end component;

    component ClockDivider
        port (
            Clk_in : in std_logic;
            Clk_out : out std_logic
        );
    end component;

	component MOUSE IS
		PORT( clock_25Mhz, reset 		: IN std_logic;
			mouse_data					: INOUT std_logic;
			mouse_clk 					: INOUT std_logic;
			left_button, right_button	: OUT std_logic;
			mouse_cursor_row 			: OUT std_logic_vector(9 DOWNTO 0); 
			mouse_cursor_column 		: OUT std_logic_vector(9 DOWNTO 0));       	
	end component MOUSE;

	component Renderer is
		port (
			clk25Mhz : IN std_logic;
			mouse_left : IN std_logic;
			vert_sync, horz_sync : IN std_logic;
			pixel_row, pixel_column	: IN std_logic_vector(9 DOWNTO 0);
			red, green, blue : OUT std_logic_vector(3 downto 0)
		)
	end component Renderer;

    signal Clk25Mhz : std_logic;
	signal red_out, blue_out, green_out : std_logic_vector(3 downto 0) := (others => '0');
	signal pixel_row, pixel_column : std_logic_vector(9 downto 0);
	signal red : std_logic_vector(3 downto 0) := "1111";
	signal green : std_logic_vector(3 downto 0) := "1000";
	signal blue : std_logic_vector(3 downto 0) := "0000";
	
	signal ball_red, ball_green, ball_blue : std_logic;
	
	signal left_button : std_logic;
	
	signal vert_sync_out : std_logic;
begin
	Clock_Divider : ClockDivider
	port map (
		Clk_in => CLOCK_50,
		Clk_out => Clk25Mhz
        );
		
		
	MOUSE_COMPONENT : MOUSE port map (
		clock_25Mhz => clk25Mhz,
		reset => '0',
		mouse_data => PS2_DAT,
		mouse_clk => PS2_CLK,
		left_button => left_button,
		right_button => open,
		mouse_cursor_row => open,
		mouse_cursor_column => open
	);

    VGA : VGA_SYNC port map (
		clock_25Mhz => Clk25Mhz,
		red => red, 
		green => green,
		blue => blue,
		red_out => red_out,
		green_out => green_out,
		blue_out => blue_out,
		horiz_sync_out => VGA_HS,
		vert_sync_out => vert_sync_out,
		pixel_row => pixel_row,
		pixel_column => pixel_column
	);
		  
	RENDERER : Renderer port map (
		clk25Mhz => Clk25Mhz,
		mouse_left => left_button,
		vert_sync => vert_sync_out,
		horz_sync => horiz_sync_out,
		pixel_row => pixel_row,
		pixel_column => pixel_column,
		red => red,
		blue => blue,
		green => green
	);

	-- blue <= "0000" when ball_blue = '1' else "1111";
	-- green <= "1000" when ball_green = '1' else "1111";
    
	VGA_R <= red_out;
	VGA_G <= green_out;
	VGA_B <= blue_out;
	VGA_VS <= vert_sync_out;
	 
end architecture behavior;