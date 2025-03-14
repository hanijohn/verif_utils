/*
Copyright (c) 2025, Hani John Poly
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of the author nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

// -----------------------------------------------------------------------------------------------
// list of clocks are provided as parameter of type enum like below.
// typedef enum {FUNC_CLK, CORE_CLK} clk_e; 
// -----------------------------------------------------------------------------------------------
interface clock_gate_checker#(type T)();
   typedef enum {START, DISABLE, TERMINATE} check_e;

   // -----------------------------------------------------------------------------------------------
   // User setting
   // -----------------------------------------------------------------------------------------------

   // Connect clock
   static logic    clk[T];
   // Enable clock gate
   bit 		   clk_gate[T];
   // Skip the clock checks for the specified duration from the time clk_gate was set
   int		   skip_check_delay[T];
   

   // -----------------------------------------------------------------------------------------------
   // Internal variables 
   // -----------------------------------------------------------------------------------------------
   int             clk_fails[T];
   bit             clk_chk_occured[T];
   event           disable_chk[T];  
   event           terminate_chk[T];
 
 
   // -----------------------------------------------------------------------------------------------
   // Internal: Start Clock checker
   // -----------------------------------------------------------------------------------------------
   task start_clock_check(T i);
      fork
      automatic T j = i;
      begin : CLK_CHECK
         $display($sformatf("%s Entered Clock Check", j.name));
         forever begin      
            wait (clk_gate[j] == 1);
            clk_chk_occured[j] = 1;
            #(skip_check_delay[j]);
            $display($sformatf("%s Start Clock Check", j.name));
            fork
            begin : CLK_CHANGE
               @(edge clk[j]);
               if (clk_gate[j] == 1) begin                
                  ++clk_fails[j];
                  $error($sformatf("%s Toggled while gated : %d", j.name, clk_fails[j]));     
               end
            end
            begin : CLK_UNGATED
               wait (clk_gate[j] == 0);
               $display($sformatf("%s Disabled Clock Gate", j.name));
               disable CLK_CHANGE;
            end
            begin : DISABLE_CHECK
               wait(disable_chk[j].triggered);
               disable CLK_CHANGE;
               disable CLK_UNGATED;
               $display($sformatf("%s Disbaled Clock Check", j.name));              
            end
            join_any
            //disable fork; // Causing indentation issue so added individual disable in the threads
            $display($sformatf("%t clk_fails %p", $time, clk_fails));
           end
         end
         begin          
            wait(terminate_chk[j].triggered);
            disable CLK_CHECK;        
            $display($sformatf("%s Terminated Clock Check", j.name));                      
         end
       join_none
   endtask
   
   
   // -----------------------------------------------------------------------------------------------
   // User : Disable clock checker for a particular clock
   // -----------------------------------------------------------------------------------------------
   function disable_clock_check(T i);
      $display($sformatf("%s Disable Clock check", i.name));
      -> disable_chk[i];
   endfunction
 
   
   // -----------------------------------------------------------------------------------------------
   // User : Terminates clock checker for a particular clock : 
   // -----------------------------------------------------------------------------------------------
   function terminate_clock_check(T i);
      $display($sformatf("%s Terminate Clock check", i.name));
      -> terminate_chk[i];
   endfunction
 
   
   // -----------------------------------------------------------------------------------------------
   // User: START or DISABLE or TERMINATE check for all the clocks
   // -----------------------------------------------------------------------------------------------
   task check(check_e stage=START);
      T	clock;
      
      clock = clock.first;    
      repeat (clock.num) begin      
         if (stage == START) begin
            clk_gate[clock] = 0;
            skip_check_delay[clock] = 0;
            clk_fails[clock] = 0;
            
            $display("starting %s", clock.name);
            start_clock_check(clock);
         end else if (stage == DISABLE) begin
            disable_clock_check(clock);
         end else if (stage == TERMINATE) begin
            terminate_clock_check(clock);
         end
 
         clock = clock.next;
      end
   endtask
                  
 
   
   final begin
      $display("##### CLOCK CHECKER REPORT #####");
      $display($sformatf("%t clk_fails %p", $time, clk_fails));    
      $display($sformatf("%t clk_chk_occured %p", $time, clk_chk_occured));
 
      foreach(clk_fails[i]) begin
         if (!clk_chk_occured[i]) begin
            $display($sformatf("%s Not Checked", i.name));
         end else if(clk_fails[i]) begin
            $display($sformatf("%s FAIL", i.name));
         end else begin
            $display($sformatf("%s PASS", i.name));
         end
      end
   end
   
endinterface

