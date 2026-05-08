LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_SIGNED.all;

entity Player is
    port (
        clk, vert_sync, mouse_left	: IN std_logic;
        pixel_row, pixel_column	: IN std_logic_vector(9 DOWNTO 0);
		red, green, blue : OUT std_logic_vector(3 downto 0);
        enabled : OUT std_logic);
end entity Player;

architecture behavior of Player is
    SIGNAL render                   : std_logic;
    SIGNAL size 					: std_logic_vector(9 DOWNTO 0);  
    SIGNAL ball_y_pos				: std_logic_vector(9 DOWNTO 0);
    SiGNAL ball_x_pos				: std_logic_vector(10 DOWNTO 0);
    SIGNAL ball_y_motion			: std_logic_vector(9 DOWNTO 0);

    SIGNAL JUMP_COUNTER             : integer range 0 to 50 := 0;
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
			-- 1. Check for jump initiation (can happen anywhere, even on the ground)
            if (mouse_left = '1') then
                JUMP_COUNTER <= 50;
            end if;

            -- 2. Determine intended motion (Jump vs Gravity)
            if (JUMP_COUNTER > 0) then
                JUMP_COUNTER <= JUMP_COUNTER - 1;
                ball_y_motion <= -CONV_STD_LOGIC_VECTOR(2, 10); -- Moving UP
            else
                ball_y_motion <= CONV_STD_LOGIC_VECTOR(2, 10);  -- Gravity (Moving DOWN)
            end if;
            
            -- 3. Apply Boundaries (These will OVERRIDE the motion if touching a wall)
            
            -- BOTTOM BOUNDARY: Stop if at the bottom AND trying to fall
            if ( ('0' & ball_y_pos >= CONV_STD_LOGIC_VECTOR(479,10) - size) and (JUMP_COUNTER = 0) ) then
                ball_y_motion <= CONV_STD_LOGIC_VECTOR(0, 10);
            end if;
            
            -- TOP BOUNDARY: Stop if at the top AND trying to go up
            if ( (ball_y_pos <= size) and (JUMP_COUNTER > 0) ) then 
                ball_y_motion <= CONV_STD_LOGIC_VECTOR(0, 10);
                JUMP_COUNTER <= 0; -- Optional: Cancel the rest of the jump so it falls immediately
            end if;
            
            -- Compute next ball Y position
            ball_y_pos <= ball_y_pos + ball_y_motion;
        end if;
    end process;
    

    enabled <= render;
    red <= "1111";
    green <= "1111";
    blue <= "1111";
end architecture behavior;