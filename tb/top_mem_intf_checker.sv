/*
Copyright (c) 2025, Hani John Poly
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of the author nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


module top_mem_intf_checker(); 

   parameter int ADDR_WIDTH  = 8;
   parameter int DATA_WIDTH  = 8;

   bit                       clk;
   // Write interface
   logic                     dp_wr_cs;
   logic [ADDR_WIDTH-1:0]    dp_wr_addr;
   logic [DATA_WIDTH-1:0]    dp_wr_data;
   // Read interface
   logic                     dp_rd_cs;
   logic [ADDR_WIDTH-1:0]    dp_rd_addr;
   logic [DATA_WIDTH-1:0]    dp_rd_data;
   // ECC signals
   logic                     dp_ecccorr; // ECC Corrected
   logic                     dp_eccderr;  // ECC Double Error detected

   // Added signals for SPRAM
   logic                     sp_cs;
   logic                     sp_we;
   logic [ADDR_WIDTH-1:0]    sp_addr;
   logic [DATA_WIDTH-1:0]    sp_wr_data;
   logic [DATA_WIDTH-1:0]    sp_rd_data;
   // ECC signals
   logic                     sp_ecccorr; // ECC Corrected
   logic                     sp_eccderr;  // ECC Double Error detected


   always #5 clk = ~clk;

   // Dual Port RAM
   dpram_model#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH))               u_dpram_model(.clk      (clk),
                                                                                              .wr_cs    (dp_wr_cs),
                                                                                              .wr_addr  (dp_wr_addr),
                                                                                              .wr_data  (dp_wr_data),
                                                                                                                    
                                                                                              .rd_cs    (dp_rd_cs),
                                                                                              .rd_addr  (dp_rd_addr),
                                                                                              .rd_data  (dp_rd_data),
                                                                                                                    
                                                                                              .ecccorr  (dp_ecccorr),
                                                                                              .eccderr  (dp_eccderr) 
                                                                                             );

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
   
   // Single Port RAM
   spram_model#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH))               u_spram_model(.clk          (clk),
                                                                                              .cs           (sp_cs),
                                                                                              .we           (sp_we),
                                                                                              .addr         (sp_addr),
                                                                                              .wr_data      (sp_wr_data),
                                                                                              .rd_data      (sp_rd_data),
                                                                                                                        
                                                                                              .ecccorr      (sp_ecccorr),
                                                                                              .eccderr      (sp_eccderr) 

                                                                                             );

   spram_intf_checker#(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH))        u_spram_checker(.clk          (clk),
                                                                                                .cs           (sp_cs),
                                                                                                .we           (sp_we),
                                                                                                .addr         (sp_addr),
                                                                                                .wr_data      (sp_wr_data),
                                                                                                .rd_data      (sp_rd_data),
                                                                                                                          
                                                                                                .ecccorr      (sp_ecccorr),
                                                                                                .eccderr      (sp_eccderr) 

                                                                                               );
   
   typedef enum bit { READ, WRITE} cmd_e;

   task drive_dpram(cmd_e write, bit[ADDR_WIDTH-1:0] addr, bit[DATA_WIDTH-1:0] data='0);
      if (write) begin
         dp_wr_cs     <= 1'b1;

         dp_wr_addr   <= addr;
         dp_wr_data   <= data;
         $info($sformatf("Initiating write to address %x with data %x", addr, data));
      end else begin
         dp_rd_cs     <= 1'b1;
         dp_rd_addr   <= addr;
         $info($sformatf("Initiating read to address %x", addr));
      end

      @(posedge clk);
      dp_wr_cs     <= 1'b0;
      dp_rd_cs     <= 1'b0;

   endtask


   task drive_spram(cmd_e write, bit[ADDR_WIDTH-1:0] address, bit[DATA_WIDTH-1:0] data='0);
      sp_cs           <= 1'b1;
      sp_addr         <= address;
      if (write) begin
         sp_we        <= 1'b1;
         sp_wr_data   <= data;
         $info($sformatf("Initiating write to address %x with data %x", address, data));
      end else begin
         sp_we        <= 1'b0;
         $info($sformatf("Initiating read to address %x", address));
      end

      @(posedge clk);
      sp_cs           <= 1'b0;

   endtask


   initial begin
      $display("\nTesting DPRAM checker\n");
      u_dpram_checker.verbose = 1;

      repeat(10) @(posedge clk);

      drive_dpram(WRITE, 'h10, 'hAB);
      drive_dpram(WRITE, 'h14, 'hCD);

      drive_dpram(READ, 'h10);
      drive_dpram(READ, 'h14);

      repeat(10) @(posedge clk);

      $display("\nTesting SPRAM checker\n");
      u_spram_checker.verbose = 1;

      drive_spram(WRITE, 'h20, 'hAB);
      drive_spram(WRITE, 'h24, 'hCD);

      drive_spram(READ, 'h20);
      drive_spram(READ, 'h24);

      repeat(10) @(posedge clk);

      $finish();
   end


endmodule
