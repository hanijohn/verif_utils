# Clock Gate Checker
This is a generic clock gate checker that can support any number of clocks. The checker is implemented as parameterized SV interface.

Checker will detect for any toggle on the gated clock and will report failure as $error.


## Connecting the clocks 
All the clocks are provided as parameter to the interface as enum type
Clocks are to the interface an always block is 

```verilog

  // Specify all clocks as enum
  typedef enum {FUNC_CLK, CORE_CLK} clk_e;

  // Clock Checker
  clock_gate_checker#(clk_e)		u_clk_chkr();

  // Connect all clocks
  always @(*) begin
    u_clk_chkr.clk[FUNC_CLK] = func_clk_gated;
    u_clk_chkr.clk[CORE_CLK] = core_clk_gated;
  end
  
```

## Start the clock checkers
Start the clock checker by invoking the task `check` with `START` enum.
This will spawn checks for all clocks and waits till the clock gate for the respective clock to be enabled.

``` verilog
  initial begin
    u_clk_chkr.check(u_clk_chkr.START);
  end
```

## Enable clock gate
At the time when design clock gates are enabled, intimate the clock gate checker by setting the variable `clk_gate`
Optionally if the check needs to be skipped for any particular duration, specify the delay to `skip_check_delay` (user needs to set the required timeunit)

Checkers will start running in the background and at any time the gated clock toggles, error will be reported "clock_enum_name Toggled while gated"

``` verilog
    u_clk_chkr.skip_check_delay[FUNC_CLK] = 1;
    u_clk_chkr.clk_gate[FUNC_CLK] = 1;
```

## Terminate clock checks
Clock checks are terminated by invoking `check` with `TERMINATE`. This kills all the spawned clock gate checkers

``` verilog
    // Terminate all clock checks
    u_clk_chkr.check(u_clk_chkr.TERMINATE);
```

## Simulation
[edaplayground](https://edaplayground.com/x/rRnM)

Experimental run requires VCS and can be done by executing below commands

```csh
cd run
make all TOP=top_clock_gate_checker
```
