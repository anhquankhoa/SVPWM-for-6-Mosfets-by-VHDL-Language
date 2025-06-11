Explain the functions of the attached code files.
- 220model.vhd, 22220pack.vhd: These are library files that facilitate function calls for operations such as multiplication, addition, and division, making programming easier and more convenient
- sin625_24bit.vhd, cos625_24 bit.vhd: These are Look-Up Tables (LUTs) used to retrieve the sine and cosine values of any angle ranging from 0 to 360 degrees Celsius. Each table contains 625
corresponding sine and cosinevalues. This approach reduces the computational load on the FPGA; however, the accuracy is moderate and depends on the number of values stored in the table.
- svpwm1. vhd: This block takes as input the desired three-phase voltage values (A, B, and C) and calculates the gating times for the six switches of the inverter. The inverter then modulates the output voltage to
achieve the desired amplitude and phase angle. In addition to the desired reference voltages (Vref), the sine and cosine values of the rotor flux angle are also required to facilitate Clarke and Park transformations.
