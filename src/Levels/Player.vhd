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
            render : OUT std_logic;
            enabled : IN std_logic;
            player_y_pos : OUT unsigned(9 downto 0);
            hit_bottom : OUT std_logic;
            invincible : IN std_logic
        );
end entity Player;

architecture behavior of Player is
    SIGNAL render_out                   : std_logic;
    SIGNAL size 					: std_logic_vector(9 DOWNTO 0);  
    SIGNAL ball_y_pos : std_logic_vector(9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(240, 10);
    SIGNAL ball_x_pos				: std_logic_vector(9 DOWNTO 0);
    signal ball_velocity : std_logic_vector(9 DOWNTO 0) := (others => '0');
	signal hit_bottom : std_logic := '0';
	signal invincible : std_logic := '0';

	 component SpriteRenderer is
		 port (
			  clk : in std_logic;

			  pixel_row    : in std_logic_vector(9 downto 0);
			  pixel_column : in std_logic_vector(9 downto 0);

			  start_x  : in std_logic_vector(10 downto 0);
			  start_y  : in std_logic_vector(10 downto 0);
			  sprite_id : in integer range 0 to 64;

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
    -- need to update in the future to support variable size sprites.
    size <= CONV_STD_LOGIC_VECTOR(17,10);

    -- ball_x_pos and ball_y_pos show the (x,y) for the top-left of the sprite
    ball_x_pos <= CONV_STD_LOGIC_VECTOR(50,10);

    -- Render Conditions (Top-left based rendering)
    render_out <= '1' when ( ('0' & pixel_column >= '0' & ball_x_pos) and ('0' & pixel_column < '0' & ball_x_pos + size) 	
				and ('0' & pixel_row >= '0' & ball_y_pos) and ('0' & pixel_row < '0' & ball_y_pos + size) )	
	            else '0';
					
					
    SPRITE_RENDERER : SpriteRenderer port map (
        clk => clk,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => '0' & ball_x_pos,
        start_y => '0' & ball_y_pos,
        sprite_id => 2,
        red => red_s,
        blue => blue_s,
        green => green_s,
        transparent => transparent
    );

    Player_Controller : process (vert_sync)
	 
    begin
        -- Move ball once every vertical sync
	    if (rising_edge(vert_sync)) then	
            if (enabled = '1') then
                -- BOTTOM BOUNDARY: Die if at the bottom AND trying to fall
                if ( ('0' & ball_y_pos >= CONV_STD_LOGIC_VECTOR(479, 10)) and (ball_velocity >= CONV_STD_LOGIC_VECTOR(0, 10)) ) then
                    if invincible = '0' then  
                        hit_bottom <= '1';
                    else
                        ball_y_pos <= CONV_STD_LOGIC_VECTOR(479, 10) - size;
                        hit_bottom <= '0';
                    end if;
                -- TOP BOUNDARY: Stop if at the top 
                elsif (ball_y_pos <= size) then 
                    ball_velocity <= CONV_STD_LOGIC_VECTOR(0, 10); 
                    ball_y_pos <= CONV_STD_LOGIC_VECTOR(0, 10) + (size + 1); -- +1 to prevent getting stuck at top boundary 
                    hit_bottom <= '0';
                else
                    ball_y_pos <= ball_y_pos + ball_velocity; 
                    hit_bottom <= '0';
                end if;

                
                -- Increase/decrease ball velocity depending on if mouse is clicked (go up) or not (fall)
                if (mouse_left = '1') then
                    ball_velocity <= jump_velocity;
                elsif (ball_velocity < fall_velocity_max) then
                    ball_velocity <= ball_velocity + gravity; 
                end if;
            end if;
        end if;
        red <= red_s;
        green <= green_s;
        blue <= blue_s;
    end process;
    
    -- glad we did it like this, cuz its so easy to do transparency!
    render <= render_out and not transparent;
    player_y_pos <= unsigned(ball_y_pos);
end architecture behavior;