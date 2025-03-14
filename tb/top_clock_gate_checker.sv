/*
Copyright (c) 2025, Hani John Poly
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of the author nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


module top_clock_gate_checker();
  
  typedef enum {FUNC_CLK, CORE_CLK} clk_e;

  bit	func_clk;
  bit	func_clk_gated;
  bit   core_clk;
  bit   core_clk_gated;
  
  bit   func_clk_en;
  bit   core_clk_en;
  
  always #5 func_clk = ~func_clk;
  always #6 core_clk = ~core_clk;
  
  assign func_clk_gated = func_clk & func_clk_en;
  assign core_clk_gated = core_clk & core_clk_en;
  
  // Clock Checker
  clock_gate_checker#(clk_e)		u_clk_chkr();
  
  // Connect all clocks
  always @(*) begin
    u_clk_chkr.clk[FUNC_CLK] = func_clk_gated;
    u_clk_chkr.clk[CORE_CLK] = core_clk_gated;
  end
  
  task test_func_clk_chk(bit pass=1);
    $display($sformatf("%t Gate functional clock", $time));
    func_clk_en = 0;
    
    $display($sformatf("%t Set the expecatation in checker", $time));
    u_clk_chkr.skip_check_delay[FUNC_CLK] = 1;
    u_clk_chkr.clk_gate[FUNC_CLK] = 1;
    
    #200;
    
    $display($sformatf("%t Ungate Functional Clock", $time));
    func_clk_en = 1;
    if (pass) begin
      $display($sformatf("%t Ungate clock checker should PASS", $time));
    end else begin
      #20;
      $display($sformatf("%t delayed disabling : checker should FAIL", $time));
    end
    u_clk_chkr.clk_gate[FUNC_CLK] = 0;

    #200;
  endtask
  
  initial begin
    bit pass = 1;
    bit fail = 0;
    
    // Start Clock checker at 0
    u_clk_chkr.check(u_clk_chkr.START);
    
    #100;
    $display($sformatf("%t Start functionnal clock", $time));
    func_clk_en = 1;    
    #100;
    $display($sformatf("%t Start core clock", $time));
    core_clk_en = 1;
    #1000;
    
    test_func_clk_chk(pass);
    #200;
    test_func_clk_chk(fail);

    #100;
    
    // Test Core Clock
    core_clk_en = 0;
    u_clk_chkr.clk_gate[CORE_CLK] = 1;    
    #200;
    core_clk_en = 1;
    u_clk_chkr.clk_gate[CORE_CLK] = 0;
    #200;
    
    
    // Terminate all clock checks
    u_clk_chkr.check(u_clk_chkr.TERMINATE);
    
    #100;
    $display("Test Completed");

    $finish;
  end
  
  
endmodule
