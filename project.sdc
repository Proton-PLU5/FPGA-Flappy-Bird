# ====================================================================
# 1. Base Hardware Clock Definition
# ====================================================================
# The physical 50 MHz oscillator pin on the DE0-CV board.
create_clock -period 20.000 -name CLOCK_50 [get_ports {CLOCK_50}]

# ====================================================================
# 2. Automated PLL Clocks & Uncertainty Derivation
# ====================================================================
# Automatically creates the 25 MHz clock constraint from your ALTPLL IP.
derive_pll_clocks
derive_clock_uncertainty

# ====================================================================
# 3. Asynchronous Input Exceptions
# ====================================================================
# Cuts timing paths for push buttons or switches so the tool doesn't waste resources.
set_false_path -from [get_ports {KEY[*] SW[*]}] -to [all_registers]

# ====================================================================
# 4. VGA Output Constraints (Using the 25 MHz PLL Clock)
# ====================================================================
# We use a wildcard {*} matching pattern to target the 25 MHz PLL clock.
# Standard DE0-CV VGA requirements allow a generic board-skew margin of ~3.0 ns.

set_output_delay -clock [get_clocks {*altpll*|clk[0]*}] 3.000 [get_ports {VGA_HS VGA_VS}]
set_output_delay -clock [get_clocks {*altpll*|clk[0]*}] 3.000 [get_ports {VGA_R[*] VGA_G[*] VGA_B[*]}]