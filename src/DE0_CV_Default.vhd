LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_SIGNED.all;

entity DE0_CV_Default is
    port (
        CLOCK_50 : in std_logic;
		  SW : in std_logic_vector(9 downto 0);
		  VGA_G, VGA_B, VGA_R : out std_logic_vector(3 downto 0);
		  VGA_HS : out std_logic;
		  VGA_VS : out std_logic;
		  PS2_DAT, PS2_CLK : INOUT std_logic;
		  HEX0 : OUT std_logic_vector(6 downto 0)
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
		   SW : in std_logic_vector(9 downto 0);
			pixel_row, pixel_column	: IN std_logic_vector(9 DOWNTO 0);
			red, green, blue : OUT std_logic_vector(3 downto 0)
		);
	end component Renderer;
	
	component BCD_to_SevenSeg is
     port (BCD_digit : in std_logic_vector(3 downto 0);
           SevenSeg_out : out std_logic_vector(6 downto 0));
	end component;

   signal Clk25Mhz : std_logic;
	signal red_out, blue_out, green_out : std_logic_vector(3 downto 0) := (others => '0');
	signal pixel_row, pixel_column : std_logic_vector(9 downto 0);
	signal red : std_logic_vector(3 downto 0);
	signal green : std_logic_vector(3 downto 0);
	signal blue : std_logic_vector(3 downto 0);
	
	signal ball_red, ball_green, ball_blue : std_logic;
	
	signal left_button : std_logic;
	
	signal vert_sync_out : std_logic;
	signal horz_sync_out : std_logic;
		
	signal count : integer range 0 to 9 := 0;
	signal mouse_down : std_Logic := '0';
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
		horiz_sync_out => horz_sync_out,
		vert_sync_out => vert_sync_out,
		pixel_row => pixel_row,
		pixel_column => pixel_column
	);
	
	COVERTER: BCD_to_SevenSeg port map (
		BCD_digit => CONV_STD_LOGIC_VECTOR(count, 4),
		SevenSeg_out => HEX0
	);
		  
	RENDERER_COMPONENT : Renderer port map (
		clk25Mhz => Clk25Mhz,
		mouse_left => left_button,
		vert_sync => vert_sync_out,
		horz_sync => horz_sync_out,
		SW => SW,
		pixel_row => pixel_row,
		pixel_column => pixel_column,
		red => red,
		green => green,
		blue => blue
	);

	-- blue <= "0000" when ball_blue = '1' else "1111";
	-- green <= "1000" when ball_green = '1' else "1111";
	
	process (clk25Mhz)
	begin
		 if rising_edge(clk25Mhz) then
			  if (left_button = '1' and mouse_down = '0') then
					if count = 9 then
						 count <= 0; -- Reset if it hits the max range
					else
						 count <= count + 1;
					end if;
					mouse_down <= '1';
			  elsif (left_button = '0') then
					mouse_down <= '0';
			  end if;
		 end if;
	end process;
    
	VGA_R <= red_out;
	VGA_G <= green_out;
	VGA_B <= blue_out;
	VGA_VS <= vert_sync_out;
	VGA_HS <= horz_sync_out;
	 
end architecture behavior;