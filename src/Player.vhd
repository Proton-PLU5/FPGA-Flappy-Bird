LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_SIGNED.all;

entity Player is
    port (
        clk, vert_sync, mouse_left	: IN std_logic;
        pixel_row, pixel_column	: IN std_logic_vector(9 DOWNTO 0);
		  KEY : IN std_logic_vector(3 DOWNTO 0);
		  red, green, blue : OUT std_logic_vector(3 downto 0);
        enabled : OUT std_logic);
end entity Player;

architecture behavior of Player is
    SIGNAL render                   : std_logic;
    SIGNAL size 					: std_logic_vector(9 DOWNTO 0);  
    SIGNAL ball_y_pos : std_logic_vector(9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(240, 10);
    SiGNAL ball_x_pos				: std_logic_vector(9 DOWNTO 0);
    signal ball_velocity : std_logic_vector(9 DOWNTO 0) := (others => '0');
	 
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
	 end component;
	 

	 signal red_s, green_s, blue_s : std_logic_vector(3 downto 0) := (others => '1');


    constant gravity : std_logic_vector(9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(2, 10);
    constant fall_velocity_max : std_logic_vector(9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(6, 10);
    constant jump_velocity : std_logic_vector(9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(-6, 10);

    signal is_pressed : std_logic := '0';
    signal transparent : std_logic := '0';

begin
    size <= CONV_STD_LOGIC_VECTOR(80,10);

    -- ball_x_pos and ball_y_pos show the (x,y) for the top-left of the sprite
    ball_x_pos <= CONV_STD_LOGIC_VECTOR(50,10);

    -- Render Conditions (Top-left based rendering)
    render <= '1' when ( ('0' & pixel_column >= '0' & ball_x_pos) and ('0' & pixel_column < '0' & ball_x_pos + size) 	
				and ('0' & pixel_row >= '0' & ball_y_pos) and ('0' & pixel_row < '0' & ball_y_pos + size) )	
	            else '0';
					
					
    SPRITE_RENDERER : SpriteRenderer port map (
        clk => clk,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => ball_x_pos,
        start_y => ball_y_pos,
        sprite_id => 0,
        red => red_s,
        blue => blue_s,
        green => green_s,
        transparent => transparent
    );

    Player_Controller : process (vert_sync)
	 
    begin
        -- Move ball once every vertical sync
	    if (rising_edge(vert_sync)) then	
        
            -- BOTTOM BOUNDARY: Stop if at the bottom AND trying to fall
            if ( ('0' & ball_y_pos >= CONV_STD_LOGIC_VECTOR(479, 10) - size) and (ball_velocity >= CONV_STD_LOGIC_VECTOR(0, 10)) ) then
                ball_y_pos <= CONV_STD_LOGIC_VECTOR(479, 10) - size;
            -- TOP BOUNDARY: Stop if at the top 
            elsif (ball_y_pos <= size) then 
                ball_velocity <= CONV_STD_LOGIC_VECTOR(0, 10); 
                ball_y_pos <= CONV_STD_LOGIC_VECTOR(0, 10) + (size + 1); -- +1 to prevent getting stuck at top boundary 
            else
                ball_y_pos <= ball_y_pos + ball_velocity; 
            end if;


			-- Increase/decrease ball velocity depending on if mouse is clicked (go up) or not (fall)
            if (mouse_left = '1') then
                ball_velocity <= jump_velocity;
            elsif (ball_velocity < fall_velocity_max) then
                ball_velocity <= ball_velocity + gravity; 
            end if;
     
       end if;
		 red <= red_s;
		 green <= green_s;
		 blue <= blue_s;
    end process;
    
    -- Enable output if within bounding box and pixel is not transparent
    enabled <= render and not transparent;
end architecture behavior;