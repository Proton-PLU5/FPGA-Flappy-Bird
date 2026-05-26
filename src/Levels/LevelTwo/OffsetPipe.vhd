library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

--Placeholder to test level 2; This is just pipe but red
entity OffsetPipe is 
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
        render                      : out std_logic;
        part_to_render              : in std_logic;
        player_y_pos                : in unsigned(9 downto 0)
    );
end entity OffsetPipe;

architecture behaviour of OffsetPipe is
    signal render_out : std_logic;
    signal pipe_x_pos : unsigned(10 downto 0) := to_unsigned(640 + START_OFFSET, 11);
    signal pipe_top_y_pos : unsigned(9 downto 0);
    signal pipe_bottom_y_pos : unsigned(9 downto 0);
    signal pipe_width : unsigned(9 downto 0) := to_unsigned(25,10);

    signal player_latched_y_pos : unsigned(9 downto 0);
    signal player_latched : std_logic := '0';
    signal is_visible : std_logic := '1';
begin
    -- Updated render_out: Now checks "enabled" so Pipe 2 stays hidden at start
    render_out <= '1' when (
        (enabled = '1') and (is_visible = '1') 
        and (pipe_x_pos <= unsigned(pixel_column) + pipe_width) 
        and (unsigned(pixel_column) <= pipe_x_pos + pipe_width)
        and (
            ((unsigned(pixel_row) <= pipe_top_y_pos) and (part_to_render = '1')) or
            ((unsigned(pixel_row) >= pipe_bottom_y_pos) and (part_to_render = '0'))
        )
    ) else '0';

    PIPE_CONTROLLER : process (vert_sync)
        -- Helper to calculate the center of the gap
        variable gap_center : unsigned(9 downto 0);
    begin
        if rising_edge(vert_sync) then
            if reset = '1' then
                end_reached <= '0';
                is_visible <= '1';
                pipe_x_pos <= to_unsigned(640 + START_OFFSET, 11);
                
                -- Initialize pipe Y positions based on the input height
                pipe_top_y_pos <= to_unsigned(height, 10) - to_unsigned(gap/2, 10);
                pipe_bottom_y_pos <= to_unsigned(height, 10) + to_unsigned(gap/2, 10);
                player_latched <= '0';
                
            elsif enabled = '1' then
                -- Movement Logic
                if pipe_x_pos <= to_unsigned(2, 11) then
                    end_reached <= '1';
                    is_visible <= '0';
                else
                    pipe_x_pos <= pipe_x_pos - to_unsigned(2, 11);
                    end_reached <= '0';
                    
                    -- Latching and "Seeking" Logic
                    if pipe_x_pos <= to_unsigned(300, 11) then -- Start seeking earlier for a smoother climb
                        if (player_latched = '0') then
                            player_latched <= '1';
                            player_latched_y_pos <= player_y_pos;
                        end if;

                        -- Calculate current gap center to decide movement
                        gap_center := pipe_top_y_pos + to_unsigned(gap/2, 10);

                        -- If gap is above player, move whole pipe system DOWN
                        if (gap_center < player_latched_y_pos - 4) then
                            pipe_top_y_pos <= pipe_top_y_pos + 4;
                            pipe_bottom_y_pos <= pipe_bottom_y_pos + 4;
                        
                        -- If gap is below player, move whole pipe system UP (climbing)
                        elsif (gap_center > player_latched_y_pos + 4) then
                            pipe_top_y_pos <= pipe_top_y_pos - 4;
                            pipe_bottom_y_pos <= pipe_bottom_y_pos - 4;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process PIPE_CONTROLLER;

    render <= render_out;
    red <= (others => '1');
    green <= (others => '0');
    blue <= (others => '0');
    x_pos <= pipe_x_pos;
end architecture behaviour;