/*
Copyright (c) 2025, Hani John Poly
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of the author nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


module dpram_model #(
                      parameter int ADDR_WIDTH = 8,
                      parameter int DATA_WIDTH = 8
                   )
                   (
                      input logic                            clk,
                      // Write interface
                      input logic                            wr_cs,
                      input logic [ADDR_WIDTH-1:0]           wr_addr,
                      input logic [DATA_WIDTH-1:0]           wr_data,
                      // Read interface
                      input logic                            rd_cs,
                      input logic [ADDR_WIDTH-1:0]           rd_addr,
                      output logic [DATA_WIDTH-1:0]          rd_data,
                      // ECC signals
                      output logic                           ecccorr, // ECC Corrected
                      output logic                           eccderr  // ECC Double Error detected
                   );


   bit                       inj_rddata_err;
   bit                       inj_ecccorr;
   bit                       inj_eccderr;
   int                       rd_dalay_cycle=1;
   bit                       delete_data_after_read;

   logic [DATA_WIDTH-1:0]    mem[bit[ADDR_WIDTH-1:0]];

   always @(posedge clk) begin
      if (wr_cs) begin
         mem[wr_addr] = wr_data;
      end
   end


   //----------------------------------------------------------------
   // Clear Memory
   //----------------------------------------------------------------
   function void clear_mem();
      mem.delete;
   endfunction


   task automatic drive(logic [ADDR_WIDTH-1:0] addr, int delay);
      bit[DATA_WIDTH-1:0]    data;

      if (mem.exists(addr)) begin
         data = mem[addr];
         if (delete_data_after_read) begin
            mem.delete(addr);
         end
      end else begin
         repeat(delay) @(posedge clk);
         rd_data = 'x;
         ecccorr = 1'bx;
         ecccorr = 1'bx;
         return;
      end

      repeat(delay) @(posedge clk);

      if (inj_rddata_err) begin
         rd_data = ~data;
      end else begin
         rd_data = data;
      end

      if (inj_ecccorr) begin
         ecccorr = 1'b1;
      end else begin
         ecccorr = 1'b0;
      end

      if (inj_eccderr) begin
         eccderr = 1'b1;
      end else begin
         eccderr = 1'b0;
      end
   endtask


   always @(posedge clk) begin
      if (rd_cs) begin
         fork
         automatic bit[ADDR_WIDTH-1:0] addr=rd_addr;
         automatic bit[ADDR_WIDTH-1:0] delay=rd_dalay_cycle;
         begin
            drive(addr, delay);
         end
         join_none
      end
   end

endmodule

