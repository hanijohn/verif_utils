# verif_utils
Verification utilities that should help with Pre-Silicon Testbench development are listed below. Click on the links to get the details

1. [User Data from File](./user_data_from_file/README.md)
At the start of the verification process, before scoreboards are established, a fixed incremental data pattern is often used as a stimulus for the design. This approach aids in debugging if any issues arise. The data typically consists of a stream of bytes, which can become complex when multiple streams, channels, or ports require unique identifiers within the pattern. 

![image info](./Drawing.png)
The `User Data From File` verification utility simplifies this process by allowing users to input a text file as the stimulus for the design.
Users can create or provide a text or log file as input to the design, and the output can similarly be converted into a human-readable format.

1. [Clock Gate Checker](./clock_gate_checker/README.md)
A generic clock gate checker that can scale to accommodate any number of clocks. Once the clock gates are activated, the checker monitors for any toggling of the clocks and reports such occurrences as errors.
