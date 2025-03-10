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
// Class : env_stub
// Verification Env Stub to get transaction from monitor
// -----------------------------------------------------------------------------------------------
class env_stub;
  //typedef bit[7:0]      payload_ar_t[];
  typedef byte      payload_ar_t[];

  payload_ar_t          data;

  function new();
  endfunction

  function payload_ar_t received_txn(payload_ar_t payload);
     payload_ar_t       d;

     d = payload;
     return(d);
  endfunction
endclass


// -----------------------------------------------------------------------------------------------
// Module to test standalone
// -----------------------------------------------------------------------------------------------
module top; 

  import verif_utils::*;

  initial begin
     stimulus_file                     sd;
     stimulus_file#()::byte_ar_t       data;
     stimulus_file#(byte)              sd_B;
     stimulus_file#(byte)::byte_ar_t   data_B;
     int                               len;

     string                            temp_s;
     int                               temp_i;

     env_stub                          es;
     env_stub::payload_ar_t            payload;

     // Reading from 4 Byte hex file
     sd = new("../user_data_from_file/input/file_4B.hex");

     len = 40;
     data = sd.get_input_byte_stream(len);
     $display("Asked %d bytes", len);
     sd.print_array_hex(data, "1st_data");
     sd.print_array_ascii(data, "1st_data");

     len = 40;
     data = sd.get_input_byte_stream(len);
     $display("Asked %d bytes", len);
     sd.print_array_hex(data, "2nd_data");
     sd.print_array_ascii(data, "2nd_data");

     len = 40;
     data = sd.get_input_byte_stream(len);
     $display("Asked %d bytes", len);
     sd.print_array_hex(data, "3rd_data");
     sd.print_array_ascii(data, "3rd_data");

     // Reading from 8 Byte hex file with skip of 2 lines
     sd = new("../user_data_from_file/input/file_8B.hex", .skip_lines(2), .bytes(8));

     len = 40;
     data = sd.get_input_byte_stream(len);
     $display("Asked %d bytes", len);
     sd.print_array_hex(data, "1st_data");
     sd.print_array_ascii(data, "1st_data");

     len = 40;
     data = sd.get_input_byte_stream(len);
     $display("Asked %d bytes", len);
     sd.print_array_hex(data, "2nd_data");
     sd.print_array_ascii(data, "2nd_data");

     len = 40;
     data = sd.get_input_byte_stream(len);
     $display("Asked %d bytes", len);
     sd.print_array_hex(data, "3rd_data");
     sd.print_array_ascii(data, "3rd_data");

     // Mimic Send data and receive transaction
     es = new();
     // Reading from 8 Byte hex file
     sd_B = new("../user_data_from_file/input/file_8B.hex", .skip_lines(0), .bytes(8));

     for (int i=0; i<3; i++) begin
        len = 40;
        data_B = sd_B.get_input_byte_stream(len);
        $display("Asked %d bytes", len);
        sd_B.print_array_hex(data_B, "1st_data");
        sd_B.print_array_ascii(data_B, "1st_data");

        payload = es.received_txn(data_B);
        sd_B.store_received_data(payload);
        sd_B.print_array_hex(sd_B.receive_data, "Received Data");
     end
     
     $display("%s", sd_B.get_stats());
     sd_B.print_array_hex(sd_B.send_data, "send data");
     sd_B.print_array_hex(sd_B.receive_data, "receive data");

     
     
  end


endmodule
