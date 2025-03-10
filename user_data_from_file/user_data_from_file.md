# User data from File
The approach presented here, allows user to generate hex data from any text file and apply that as stimulus, as a byte array. 
Similary, the output data from design can be written to a hex file, which can be coverted as an ascii text file. 
An example of "Hello World" message passed through design can be found in the 'input' folder

## Unix Commands for text file <-> hex file

### Convert Text to hex file - 4 Byte data in one line
Lesser lines smaller the file size in comparison with 1 Byte lines
```csh
od -t x4z -w4 file.txt > file_4B.hex
```

### Convert Text to hex file - 8 Byte data in one line
```csh
od -t x8z -w8 file.txt > file_8B.hex
```

### Generate ASCII file with 4 Hex Byte
```csh
cat file_4B.hex.out | sed -r 's/(..)(..)(..)(..)/\4\3\2\1/' | xxd -r -p
```

### Generate ASCII file with 8 Hex Byte
```csh
cat file_8B.hex.out | sed -r 's/(..)(..)(..)(..)(..)(..)(..)(..)/\8\7\6\5\4\3\2\1/' | xxd -r -p
```

## Systemverilog API
Systemverilog implementation is encapsulated in class ```stimulus_file. The hex file needs be passed while constructing along with few other parameters, complete list below

### constructor
Mandatory parameter hex file name and other optional arguments
- name : hex file name
- skip_lines : default 0 | number of lines to be skipped from hex file
- data_char_position : default 8 | coloumn position of start of data charater in hex file
- bytes : default 4 | Byte length of each line in the nex file
- single_read_lines : default 100 | Number of lines read from the hex file. Used to optimize memory usage. Avoids creating big storage for large sized files.


### get_input_byte_stream
function to return a byte array Queue. The number of bytes to be reutruned is given as parameter.


### print_array_hex
function to print array in hex. Pass the array and a string identifier as parameter.

### print_array_ascii
function to print array in ACSII. Pass the array and a string identifier as parameter.


### store_received_data
function to store data that can be written to hex file. Pass the array as parameter.
The hex file is created after the total byte count reaches to what was sent.

### Example
Below code has the complete use model


```verilog
     stimulus_file#(byte)              sd_B;
     stimulus_file#(byte)::byte_ar_t   data_B;
     int                               len;
     env_stub                          es;
     env_stub::payload_ar_t            payload;


     // Reading from 8 Byte hex file
     sd_B = new("../input/file_8B.hex", .skip_lines(0), .bytes(8));

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
```
