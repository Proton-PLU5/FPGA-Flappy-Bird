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
    SiGNAL ball_x_pos				: std_logic_vector(10 DOWNTO 0);
    signal ball_velocity : std_logic_vector(9 DOWNTO 0) := (others => '0');

	 signal red_s, green_s, blue_s : std_logic_vector(3 downto 0) := (others => '1');


    constant gravity : std_logic_vector(9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(2, 10);
    constant fall_velocity_max : std_logic_vector(9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(6, 10);
    constant jump_velocity : std_logic_vector(9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(-6, 10);

    signal is_pressed : std_logic := '0';


begin
    size <= CONV_STD_LOGIC_VECTOR(8,10);

    -- ball_x_pos and ball_y_pos show the (x,y) for the centre of ball
    ball_x_pos <= CONV_STD_LOGIC_VECTOR(50,11);

    -- Render Conditions
    -- (When we use sprites we can create like a process for creating this based on like an image)
    render <= '1' when ( ('0' & ball_x_pos <= '0' & pixel_column + size) and ('0' & pixel_column <= '0' & ball_x_pos + size) 	-- x_pos - size <= pixel_column <= x_pos + size
				and ('0' & ball_y_pos <= pixel_row + size) and ('0' & pixel_row <= ball_y_pos + size) )	-- y_pos - size <= pixel_row <= y_pos + size
	            else '0';

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
            
				
				--Push button flips ball colour
				if (KEY(0) = '0' and is_pressed = '0') then
					red_s <= not red_s;
					green_s <= not green_s;
					blue_s <= not blue_s;
					is_pressed <= '1';
                elsif (KEY(0) = '1') then
                    is_pressed <= '0';
                end if;

        end if;
		 red <= red_s;
		 green <= green_s;
		 blue <= blue_s;
    end process;
    

    enabled <= render;
end architecture behavior;