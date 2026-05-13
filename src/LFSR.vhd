LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_SIGNED.all;

entity LFSR is
    port (
        clk : IN std_logic;
        reset : IN std_logic;
        enable : IN std_logic;
        random_out : OUT std_logic_vector(7 downto 0)
    );
end entity LFSR;

architecture behaviour of LFSR is
    signal output : std_logic_vector(7 downto 0) := x"FF"; -- Initial seed value
begin
    GENERATOR: process(clk, reset)
        variable temp : std_logic := '0';
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                output <= x"FF";
            elsif (enable = '1') then
                -- Really simple LFSR that just flips bits 4, 3, 2, and 0 and then shifts everything to the right.
                -- should be enough for our purposes, but might want to make it better in the future?
                temp := output(4) XOR output(3) XOR output(2) XOR output(0);
                output <= temp & output(7 downto 1);
            end if;
        end if;
    end process GENERATOR;

    random_out <= output;
end architecture behaviour;