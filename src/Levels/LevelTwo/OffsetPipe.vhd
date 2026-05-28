library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity OffsetPipe is 
    generic (
        START_OFFSET : integer := 0
    );
    port (
        clk, vert_sync, mouse_left  : in std_logic;
        pixel_row, pixel_column     : in std_logic_vector(9 downto 0);
        red, green, blue            : out std_logic_vector(3 downto 0);
        height                      : in integer range 0 to 480;
        gap                         : in integer range 0 to 480;
        reset                       : in std_logic;
        end_reached                 : out std_logic;
        x_pos                       : out unsigned(10 downto 0);
        enabled                     : in std_logic;
        render                      : out std_logic;
        part_to_render              : in std_logic; -- '1' = top, '0' = bottom
        player_y_pos                : in unsigned(9 downto 0)
    );
end entity;

architecture behaviour of OffsetPipe is

    constant BONE_CAP_WIDTH   : integer := 45;
    constant BONE_CAP_HEIGHT  : integer := 25;
    constant BONE_BODY_WIDTH  : integer := 25;

    constant SPEED : integer := 4;

    constant SCREEN_H : integer := 480;

    constant BONE_CAP_SPRITE_ID  : integer := 13;
    constant BONE_BODY_SPRITE_ID : integer := 12;

    signal pipe_x_pos : unsigned(10 downto 0) := to_unsigned(640 + START_OFFSET, 11);

    signal cap_x_offset : unsigned(10 downto 0) :=
        to_unsigned((BONE_CAP_WIDTH - BONE_BODY_WIDTH) / 2, 11);

    signal pipe_top_y_pos     : unsigned(9 downto 0);
    signal pipe_bottom_y_pos  : unsigned(9 downto 0);

    signal top_cap_start_y    : unsigned(10 downto 0);
    signal bottom_cap_start_y : unsigned(10 downto 0);

    signal player_latched_y_pos : unsigned(9 downto 0);
    signal player_latched       : std_logic := '0';
    signal growth_enabled       : std_logic := '0';
    signal is_visible           : std_logic := '1';

    -- renderer outputs
    signal top_cap_r, top_cap_g, top_cap_b : std_logic_vector(3 downto 0);
    signal top_body_r, top_body_g, top_body_b : std_logic_vector(3 downto 0);
    signal bot_cap_r, bot_cap_g, bot_cap_b : std_logic_vector(3 downto 0);
    signal bot_body_r, bot_body_g, bot_body_b : std_logic_vector(3 downto 0);

    signal top_cap_t, top_body_t, bot_cap_t, bot_body_t : std_logic;

    signal render_top_cap, render_top_body, render_bottom_cap, render_bottom_body : std_logic;

    component SpriteRenderer is
        port (
            clk          : in  std_logic;
            pixel_row    : in  std_logic_vector(9 downto 0);
            pixel_column : in  std_logic_vector(9 downto 0);
            start_x      : in  std_logic_vector(10 downto 0);
            start_y      : in  std_logic_vector(10 downto 0);
            sprite_id    : in  integer range 0 to 64;
            flip_y       : in  std_logic := '0';
            red          : out std_logic_vector(3 downto 0);
            green        : out std_logic_vector(3 downto 0);
            blue         : out std_logic_vector(3 downto 0);
            transparent  : out std_logic
        );
    end component;

begin

    -----------------------------------------------------------------
    -- GEOMETRY
    -----------------------------------------------------------------
    top_cap_start_y    <= ('0' & pipe_top_y_pos) - to_unsigned(BONE_CAP_HEIGHT, 11);
    bottom_cap_start_y <= '0' & pipe_bottom_y_pos;

    -----------------------------------------------------------------
    -- RENDER MASKS
    -----------------------------------------------------------------

    render_top_cap <= '1' when (
        enabled = '1' and is_visible = '1' and part_to_render = '1'
        and unsigned(pixel_column) >= pipe_x_pos - cap_x_offset
        and unsigned(pixel_column) <  pipe_x_pos - cap_x_offset + BONE_CAP_WIDTH
        and unsigned(pixel_row)    >= top_cap_start_y(9 downto 0)
        and unsigned(pixel_row)    <  pipe_top_y_pos
        and top_cap_t = '0'
    ) else '0';

    render_top_body <= '1' when (
        enabled = '1' and is_visible = '1' and part_to_render = '1'
        and unsigned(pixel_column) >= pipe_x_pos
        and unsigned(pixel_column) <  pipe_x_pos + BONE_BODY_WIDTH
        and unsigned(pixel_row)    <  top_cap_start_y(9 downto 0)
        and top_body_t = '0'
    ) else '0';

    render_bottom_cap <= '1' when (
        enabled = '1' and is_visible = '1' and part_to_render = '0'
        and unsigned(pixel_column) >= pipe_x_pos - cap_x_offset
        and unsigned(pixel_column) <  pipe_x_pos - cap_x_offset + BONE_CAP_WIDTH
        and unsigned(pixel_row)    >= pipe_bottom_y_pos
        and unsigned(pixel_row)    <  bottom_cap_start_y(9 downto 0) + BONE_CAP_HEIGHT
        and bot_cap_t = '0'
    ) else '0';

    render_bottom_body <= '1' when (
        enabled = '1' and is_visible = '1' and part_to_render = '0'
        and unsigned(pixel_column) >= pipe_x_pos
        and unsigned(pixel_column) <  pipe_x_pos + BONE_BODY_WIDTH
        and unsigned(pixel_row)    >= bottom_cap_start_y(9 downto 0) + BONE_CAP_HEIGHT
        and bot_body_t = '0'
    ) else '0';

    render <= render_top_cap or render_top_body or render_bottom_cap or render_bottom_body;

    -----------------------------------------------------------------
    -- RGB MUX
    -----------------------------------------------------------------
    red <=
        top_cap_r when render_top_cap = '1' else
        bot_cap_r when render_bottom_cap = '1' else
        top_body_r when render_top_body = '1' else
        bot_body_r;

    green <=
        top_cap_g when render_top_cap = '1' else
        bot_cap_g when render_bottom_cap = '1' else
        top_body_g when render_top_body = '1' else
        bot_body_g;

    blue <=
        top_cap_b when render_top_cap = '1' else
        bot_cap_b when render_bottom_cap = '1' else
        top_body_b when render_top_body = '1' else
        bot_body_b;

    x_pos <= pipe_x_pos;

    -----------------------------------------------------------------
    -- SPRITE INSTANCES (FIXED SIGNALS)
    -----------------------------------------------------------------

    TOP_CAP : SpriteRenderer port map (
        clk => clk,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => std_logic_vector(pipe_x_pos - cap_x_offset),
        start_y => std_logic_vector(top_cap_start_y),
        sprite_id => BONE_CAP_SPRITE_ID,
        flip_y => '1',
        red => top_cap_r,
        green => top_cap_g,
        blue => top_cap_b,
        transparent => top_cap_t
    );

    TOP_BODY : SpriteRenderer port map (
        clk => clk,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => std_logic_vector(pipe_x_pos),
        start_y => (others => '0'),
        sprite_id => BONE_BODY_SPRITE_ID,
        flip_y => '0',
        red => top_body_r,
        green => top_body_g,
        blue => top_body_b,
        transparent => top_body_t
    );

    BOTTOM_CAP : SpriteRenderer port map (
        clk => clk,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => std_logic_vector(pipe_x_pos - cap_x_offset),
        start_y => std_logic_vector(bottom_cap_start_y),
        sprite_id => BONE_CAP_SPRITE_ID,
        flip_y => '0',
        red => bot_cap_r,
        green => bot_cap_g,
        blue => bot_cap_b,
        transparent => bot_cap_t
    );

    BOTTOM_BODY : SpriteRenderer port map (
        clk => clk,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        start_x => std_logic_vector(pipe_x_pos),
        start_y => (others => '0'),
        sprite_id => BONE_BODY_SPRITE_ID,
        flip_y => '0',
        red => bot_body_r,
        green => bot_body_g,
        blue => bot_body_b,
        transparent => bot_body_t
    );

    PIPE_CONTROLLER : process(vert_sync)
        variable gap_center   : unsigned(10 downto 0);
        constant GROWTH_SPEED : unsigned(9 downto 0) := to_unsigned(5, 10);
    begin
        if rising_edge(vert_sync) then

            if reset = '1' then
                pipe_x_pos     <= to_unsigned(640 + START_OFFSET, 11);
                player_latched <= '0';
                growth_enabled <= '0';
                is_visible     <= '1';
                end_reached    <= '0';
                pipe_top_y_pos    <= to_unsigned(height, 10) - to_unsigned(gap/2, 10);
                pipe_bottom_y_pos <= to_unsigned(height, 10) + to_unsigned(gap/2, 10);

            elsif enabled = '1' then
                -- move pipe leftward
                if pipe_x_pos > to_unsigned(SPEED, 11) then
                    pipe_x_pos <= pipe_x_pos - to_unsigned(SPEED, 11);
                else
                    end_reached <= '1';
                    is_visible  <= '0';
                end if;

                -- latch player
                if (pipe_x_pos <= to_unsigned(300, 11)) and player_latched = '0' then
                    player_latched       <= '1';
                    player_latched_y_pos <= player_y_pos;
                    growth_enabled       <= '1';
                end if;

                -- safe center calc (no DSP inference)
                gap_center := resize(pipe_top_y_pos, 11) + resize(pipe_bottom_y_pos, 11);
                gap_center := '0' & gap_center(10 downto 1);

                -- accelerated growth
                if growth_enabled = '1' and is_visible = '1' then
                    if part_to_render = '1' then
                        if gap_center < resize(player_latched_y_pos, 11) - 4 then
                            -- Use your custom speed constant here
                            if pipe_top_y_pos < to_unsigned(SCREEN_H - 10, 10) then
                                pipe_top_y_pos    <= pipe_top_y_pos + GROWTH_SPEED;
                                pipe_bottom_y_pos <= pipe_bottom_y_pos + GROWTH_SPEED;
                            end if;
                        end if;
                    else
                        if gap_center > resize(player_latched_y_pos, 11) + 4 then
                            if pipe_top_y_pos > to_unsigned(10, 10) then
                                pipe_top_y_pos    <= pipe_top_y_pos - GROWTH_SPEED;
                                pipe_bottom_y_pos <= pipe_bottom_y_pos - GROWTH_SPEED;
                            end if;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

end architecture;