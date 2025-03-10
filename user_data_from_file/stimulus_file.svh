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
// Class : stimulus_file
// Gets input data from file
// -----------------------------------------------------------------------------------------------
class stimulus_file#(type T=bit[7:0]);
   typedef T       byte_ar_t[$];

   byte_ar_t       send_data;                         // Data byte array to be sent
   byte_ar_t       receive_data;                      // Data byte array to be received
   int             total_byte_count;                  // Total Byte count sent
   int             padded_byte_count;                 // Number of padded bytes (bytes requested, but not available in file)

   string          file_name;                         // File Name
   int             fh_pos;                            // File handle position, for updating the next page 

   bit             began;                             // Flag set once the data fetch begins
   bit             file_empty;                        // Flag set when file is empty
   int             line_offset;                       // Skips top lines from the file
   int             skip_line_cnt;                     // Temp counter
   int             data_pos;                          // Data position in file
   int             byte_len;                          // Number of Bytes in file
   int             page_size;                         // Number of lines read from file in one go


   // -----------------------------------------------------------------------------------------------
   // Constructor:
   // skip_lines             : skip lines from top of the file
   // data_char_position     : position of the data character in the line
   // byte_length            : Number of data bytes in the line
   // single_read_lines      : Specify the number of lines to be read: This is to limit the data array size
   // -----------------------------------------------------------------------------------------------
   function new(string name, int skip_lines=0, int data_char_position=8, int bytes=4, int single_read_lines=100);
      file_name         = name;
      line_offset       = skip_lines;
      data_pos          = data_char_position;
      byte_len          = bytes;
      page_size         = single_read_lines;
   endfunction


   // -----------------------------------------------------------------------------------------------
   // Print data array in hex
   // -----------------------------------------------------------------------------------------------
   function void print_array_hex(byte_ar_t data, string name);
      int          cnt;

      $display("Print Array %s", name);
      foreach(data[i]) begin
         $write("%2x",data[i]);
         ++cnt;
         if (cnt % byte_len == 0 ) $display();
      end
      $display();
   endfunction


   // -----------------------------------------------------------------------------------------------
   // Print data array in ascii
   // -----------------------------------------------------------------------------------------------
   function void print_array_ascii(byte_ar_t data, string name);
      int          cnt;
      string       str=" ";

      $display("Print Array %s | str '%s'", name, str);
      foreach(data[i]) begin
         str.putc(0, data[i]);
         $write("%s",str);
         ++cnt;
         if (cnt % byte_len == 0 ) $display();
      end
      $display();
   endfunction


   // -----------------------------------------------------------------------------------------------
   // Read input data file, which is in hex format
   // Eg: hex line
   // 0000000 6c6c6548  >Hell<
   // data_pos : Start character position of line
   // byte_len : Number of characters to be read will by 2*byte_len
   // -----------------------------------------------------------------------------------------------
   function byte_ar_t extract_byte(int fh);
      int          code;
      string       line;
      string       s;
      byte_ar_t    data;

      code = $fgets(line, fh);
      // skip lines if provided
      if (skip_line_cnt < line_offset) begin
         ++skip_line_cnt;
         return(data);
      end

      s = line.substr(data_pos, data_pos+(2*byte_len)-1);
      if (!s.len()) return(data);

      // Found data bytes in the line
      for(int i=0; i<byte_len; i++) begin
        data.push_back(s.substr(i*2,i*2+1).atohex()); 
      end

      total_byte_count += byte_len;

      return(data);
   endfunction


   // -----------------------------------------------------------------------------------------------
   // Read input data file, which is in hex format
   // If lines argument is 0, the complete file is read and stored in data array
   // if lines argument is >0, those many lines are read from the file and stored in data array
   // -----------------------------------------------------------------------------------------------
   function byte_ar_t read_file(int lines=0);
      int          fh;
      int          num;
      int          code;
      string       s;
      byte_ar_t    data;

      if (file_empty) return(data);

      fh = $fopen(file_name, "r");

      $display("read_file : lines %d : fh_pos %d", lines, fh_pos);
      if (!lines) begin
         while (!$feof(fh)) begin
            data = {data, extract_byte(fh)};
         end
         $display("End of File: no more data");
         file_empty = 1;

         total_byte_count = data.size();
      end
      else begin
         if (began) begin
            code = $fseek(fh, fh_pos, 0);
         end

         while (num != lines) begin
            if ($feof(fh)) begin
               $display("End of File: no more data");
               file_empty = 1;
               break;
            end
            data = {data, extract_byte(fh)};
            ++num;
         end
         began = 1;
      end
      $fclose(fh);

      return(data);
   endfunction


   // -----------------------------------------------------------------------------------------------
   // Read input data file, which is in hex format
   // -----------------------------------------------------------------------------------------------
   function byte_ar_t get_input_byte_stream(int size, int byte_offset=0);
      int               lines;
      byte_ar_t         data_ret;
      string            msg;

      $display("get_input_byte_stream : size %d | send_data.size() %d", size, send_data.size());

      // Load Data Memory, in case enough send_data is not available
      if (send_data.size() < size) begin
         send_data = {send_data, read_file(page_size)};
         print_array_hex(send_data, "send_data");
      end

      // Retrieve from Data Memory
      while (size) begin
         if(send_data.size()) begin
            data_ret.push_back(send_data.pop_front());
         end
         else begin
            data_ret.push_back('h3F); // hex value for ascii '?'
            ++total_byte_count;
            ++padded_byte_count;
         end
         --size;
      end

      return(data_ret);
   endfunction


   // -----------------------------------------------------------------------------------------------
   // Store received data
   // -----------------------------------------------------------------------------------------------
   function void store_received_data(byte_ar_t data);
      receive_data = {receive_data, data};

      if (receive_data.size() == total_byte_count) begin
         write_outputfile({file_name , ".out"});
      end
   endfunction


   // -----------------------------------------------------------------------------------------------
   // Write received data to a file
   // -----------------------------------------------------------------------------------------------
   function void write_outputfile(string file);
      int               fh;
      int               cnt;

      byte_ar_t         data;

      $display("writing data to output file %s", file);

      data = receive_data;
      fh = $fopen(file, "w");
      while (receive_data.size()) begin
         $fwrite(fh, "%2x", receive_data.pop_front());

         ++cnt;
         if (cnt % byte_len == 0 ) $fdisplay(fh);
      end

      $fclose(fh);
   endfunction


   // -----------------------------------------------------------------------------------------------
   // stats
   // -----------------------------------------------------------------------------------------------
   function string get_stats();
      string                 msg;

      msg = $sformatf("############# Data Statistics with File %s ###############\n", file_name);
      msg = {msg, $sformatf("Total Byte count : %d\n", total_byte_count)};
      msg = {msg, $sformatf("Padded Byte count : %d\n", padded_byte_count)};

      return(msg);
   endfunction
endclass



