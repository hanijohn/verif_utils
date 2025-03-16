/*
Copyright (c) 2025, Hani John Poly
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of the author nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


// Dual Port Ram Interface checker
interface spram_intf_checker #(
                                 parameter int ADDR_WIDTH = 8,
                                 parameter int DATA_WIDTH = 8
                              )
                              (
                                 input logic                            clk,
                                 // Write interface
                                 input logic                            cs,
                                 input logic                            we,
                                 input logic [ADDR_WIDTH-1:0]           addr,
                                 input logic [DATA_WIDTH-1:0]           wr_data,
                                 input logic [DATA_WIDTH-1:0]           rd_data,
                                 // ECC signals
                                 input logic                            ecccorr, // ECC Corrected
                                 input logic                            eccderr  // ECC Double Error detected
                              );

   //----------------------------------------------------------------
   // User variables
   //----------------------------------------------------------------
   // Start checker
   bit             check_any_unknown;
   // $warning can be promoted to $error
   bit             promote_warning;
   // $error can be demoted to $warning
   bit             demote_error;
   // Read delay cycles
   int             rd_delay_cycle=2;
   // Increased Verbose
   bit             verbose;
   // Memory Initialized
   bit             mem_initialized;
   // Data memory data after read (To optimize sim memory)
   // Assuming the design reads only once
   bit             delete_data_after_read;

   // Input port sample delay
   int             input_sample_delay=1;

   //----------------------------------------------------------------
   // Internal variables
   //----------------------------------------------------------------
   logic [DATA_WIDTH-1:0]    mem[bit[ADDR_WIDTH-1:0]];

   //----------------------------------------------------------------
   // To promote warning to error
   //----------------------------------------------------------------
   function void warning(string m);
      if (promote_warning) begin
         $error(m);
      end else begin
         $warning(m);
      end
   endfunction

   //----------------------------------------------------------------
   // To promote warning to error
   //----------------------------------------------------------------
   function void error(string m);
      if (demote_error) begin
         $warning(m);
      end else begin
         $error(m);
      end
   endfunction


   //----------------------------------------------------------------
   // Check if any signals have x or z
   //----------------------------------------------------------------
   always @(*) begin
      if (check_any_unknown) begin
         if ($isunknown(cs) || $isunknown(we) || $isunknown(addr) || $isunknown(wr_data)) begin
            warning("Unknown detected on Write Interface");
         end
         if ($isunknown(rd_data)) begin
            warning("Unknown detected on Read data");
         end
         if ($isunknown(ecccorr) || $isunknown(eccderr)) begin
            warning("Unknown detected on ECC Interface");
         end
      end
   end


   //----------------------------------------------------------------
   // Clear Memory
   //----------------------------------------------------------------
   function void clear_mem();
      mem.delete;
   endfunction


   //----------------------------------------------------------------
   // Write to Memory
   //----------------------------------------------------------------
   always @(posedge clk) begin
      #input_sample_delay;

      if (cs && we) begin
         mem[addr] = wr_data;
      end
   end


   //----------------------------------------------------------------
   // Check Read Interface
   //----------------------------------------------------------------
   task automatic check(logic [ADDR_WIDTH-1:0] addr, int delay);
      bit[DATA_WIDTH-1:0]    data;

      if (mem.exists(addr)) begin
         data = mem[addr];
         if (delete_data_after_read) begin
            mem.delete(addr);
         end
         repeat(delay) @(posedge clk);
         #input_sample_delay;

         if (rd_data !== data) begin
            error($sformatf("Read data mismatch for address %x: written data %x | read data %x", addr, data, rd_data));
         end
         else if (verbose) begin
            $info($sformatf("Read data match for address %x: written data %x | read data %x", addr, data, rd_data));
         end

         if (ecccorr) begin
            $display($sformatf("Detected ECC Corrected RAM data %x at address %x", rd_data, addr));
         end

         if (eccderr) begin
            $display($sformatf("Detected ECC Double Error for RAM data %x at address %x", rd_data, addr));
         end
      end else begin
         repeat(delay) @(posedge clk);
         #input_sample_delay;

         warning($sformatf("Read Address %0x was not written to the memory before", addr));
         if (!mem_initialized && !$isunknown(data)) begin
            error($sformatf("At address %x valid data detected when memory is not initialized", addr));
         end
      end
   endtask

   always @(posedge clk) begin
      #input_sample_delay;

      if (cs && !we) begin
         fork
         automatic bit[ADDR_WIDTH-1:0] address=addr;
         automatic bit[ADDR_WIDTH-1:0] delay=rd_delay_cycle;
         begin
            if (verbose) begin
               $info($sformatf("Initiating check for address %x", address));
            end
            check(address, delay);
         end
         join_none
      end
   end


endinterface
