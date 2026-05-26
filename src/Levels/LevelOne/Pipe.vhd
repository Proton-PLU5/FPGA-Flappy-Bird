library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity Pipe is 
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
        follow_enable               : in std_logic;
        follow_x_pos                : in unsigned(10 downto 0);
        render                      : out std_logic
    );
end entity Pipe;

architecture behaviour of Pipe is
    signal render_out : std_logic;
    signal pipe_x_pos : unsigned(10 downto 0) := to_unsigned(640 + START_OFFSET, 11); -- Start off-screen right (staggerable)
    signal pipe_x_pos_effective : unsigned(10 downto 0);
    signal pipe_top_y_pos : unsigned(9 downto 0);
    signal pipe_bottom_y_pos : unsigned(9 downto 0);
    signal pipe_width : unsigned(9 downto 0) := to_unsigned(25,10);
begin
    -- Calculate top and bottom y positions based on height and gap
    pipe_top_y_pos <= to_unsigned(height, 10) - to_unsigned(gap/2, 10);
    pipe_bottom_y_pos <= to_unsigned(height, 10) + to_unsigned(gap/2, 10);

    pipe_x_pos_effective <= follow_x_pos + to_unsigned(START_OFFSET, 11) when follow_enable = '1'
                            else pipe_x_pos;

    -- render_out logic
    render_out <= '1' when (
        (pipe_x_pos_effective <= unsigned(pixel_column) + pipe_width) and (unsigned(pixel_column) <= pipe_x_pos_effective + pipe_width)
        and ( (unsigned(pixel_row) <= pipe_top_y_pos) or (unsigned(pixel_row) >= pipe_bottom_y_pos) )
    ) else '0';

    PIPE_CONTROLLER : process (vert_sync)
    begin
        if rising_edge(vert_sync) then
            -- RESET
            if reset = '1' then
                if follow_enable = '0' then
                    pipe_x_pos <= to_unsigned(640 + START_OFFSET, 11); -- Jump to right edge
                end if;
                end_reached <= '0';

            -- NORMAL MOVEMENT
            elsif enabled = '1' then
                if follow_enable = '0' then
                    
                    -- FIX: Check against 2 instead
                    if pipe_x_pos <= to_unsigned(2, 11) then
                        end_reached <= '1';
                    else
                        pipe_x_pos <= pipe_x_pos - to_unsigned(2, 11);
                        end_reached <= '0';
                    end if;
                else
                    end_reached <= '0';
                end if;

            -- PAUSED BEHAVIOUR
            else
                null; -- DO NOTHING
            end if;
        end if;
    end process PIPE_CONTROLLER;

    render <= render_out;
    red <= (others => '0');
    green <= (others => '1');
    blue <= (others => '0');
    x_pos <= pipe_x_pos_effective;
end architecture behaviour;