# Memory Interface Checker
This checker is to validate the read data matches to the written data to the memory. Two types of memory checkers are given here

## Dual Port RAM checker
In Dual Port RAMs, there are distinct interfaces for writing and reading operations. Data written is stored in the internal memory, while for reading, the data retrieved from the interface is verified against the internal memory. The checker is designed as a parameterized interface to accommodate different address and data widths.

### Instantiating checker
```verilog
   dpram_intf_checker#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH))        u_dpram_checker(.clk      (clk),
                                                                                                .wr_cs    (dp_wr_cs),
                                                                                                .wr_addr  (dp_wr_addr),
                                                                                                .wr_data  (dp_wr_data),
                                                                                                                      
                                                                                                .rd_cs    (dp_rd_cs),
                                                                                                .rd_addr  (dp_rd_addr),
                                                                                                .rd_data  (dp_rd_data),
                                                                                                                      
                                                                                                .ecccorr  (dp_ecccorr),
                                                                                                .eccderr  (dp_eccderr) 

                                                                                               );
```

### APIs
1. Read Delay cycle
   Provide the number of cycles for Read Data. 
   The default setting is 2
   ```verilog
      u_dpram_checker.rd_delay_cycle = 3;
   ```
1. Input sample delay
   Provide the delay to sample input signals.
   The default setting is 1 timeunit
   ```verilog
      u_dpram_checker.input_sample_delay = 10;
   ```
1. Increased verbosity
   Prints the data matching accesses.
   The default setting is 0
   ```verilog
      u_dpram_checker.verbose = 1;
   ```
1. Checks unknown value on interface signals
   The default setting is 0.
   ```verilog
      u_dpram_checker.check_any_unknown = 1;
   ```
1. Memory already Initialized
   Indicate whether the memory model has already been initialized. If the memory model was initialized, the data read from unwritten locations should not be unknown.
   The default setting is 0.
   ```verilog
      u_dpram_checker.mem_initialized = 1;
   ```
1. Delete after Read
   Erase memory data after it is read. This action will help decrease memory usage during simulation. 
   The default setting is 0.
   ```verilog
      u_dpram_checker.delete_data_after_read = 1;
   ```

## Single Port RAM checker
Single port RAM operates on the same interface for both writes and reads. The checker is designed as a parameterized interface to accommodate different address and data widths.

### Instantiating checker
```verilog
   spram_intf_checker#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH))        u_spram_checker(.clk          (clk),
                                                                                                .cs           (sp_cs),
                                                                                                .we           (sp_we),
                                                                                                .addr         (sp_addr),
                                                                                                .wr_data      (sp_wr_data),
                                                                                                .rd_data      (sp_rd_data),
                                                                                                                          
                                                                                                .ecccorr      (sp_ecccorr),
                                                                                                .eccderr      (sp_eccderr) 
```

## API
APIs are common for both the checkers

1. Read Delay cycle
   Provide the number of cycles for Read Data. 
   The default setting is 2
   ```verilog
      u_mem_checker.rd_delay_cycle = 3;
   ```
1. Input sample delay
   Provide the delay to sample input signals.
   The default setting is 1 timeunit
   ```verilog
      u_mem_checker.input_sample_delay = 10;
   ```
1. Increase verbosity
   This will enable prints for the data matching accesses.
   The default setting is 0
   ```verilog
      u_mem_checker.verbose = 1;
   ```
1. Checks unknown value on interface signals
   The default setting is 0. This can be set to 1 when there is no unknown expected on memory interface signal.
   ```verilog
      u_mem_checker.check_any_unknown = 1;
   ```
1. Memory already Initialized
   Indicate whether the memory model has already been initialized. If the memory model was initialized, the data read from locations that were not written should not be unknown.
   The default setting is 0.
   ```verilog
      u_mem_checker.mem_initialized = 1;
   ```
1. Delete after Read
   Erase memory data after it is read. This action will help decrease memory usage during simulation. 
   The default setting is 0.
   ```verilog
      u_mem_checker.delete_data_after_read = 1;
   ```

## Simulation
[edaplayground](https://edaplayground.com/x/rZTY)

Experimental run requires VCS and can be done by executing below commands

```csh
cd run
make all TOP=top_mem_intf_checker
```
