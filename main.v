module main (
    //Inputs
    input wire clk,                 
    input wire rst,                 
    input wire enable,              //go out from IDLE state(1)

    //Outputs
    output wire [8-1:0] displays,
    output wire [7:0] segments,

    //Inout
    inout wire scl,                 //I2C master's SCL is bidirect I/O
    inout wire sda                  //I2C master's SDA is bidirect I/O
);

//Instance module from file I2C_master.v
wire [15:0] i2c_temperature_number;
wire clk_i2c;
wire clk_segment;

I2C_master I2C(
    .clk_double(clk_i2c),                              
    .rst(rst),                                      
    .enable(enable),                                //start transfer, go out of IDLE and go to START
    .temperature_number(i2c_temperature_number),    //output data from temperature sensor
    .scl(scl),                                      
    .sda(sda)                                       
);

//Instance module from file clk_divider.v
clk_divider #(.DIVIDE(6_250)) clk_i2c_master(
    .input_clk(clk),            
    .rst(rst),
    .output_clk(clk_i2c)
);

//Instance module from file bcd.v
wire [31:0] numbers1_2;                     //8 displays, numbers 0-9 (4-bit), 8*4=32 bits to bcd
assign numbers1_2[31:25] = 0;               //unused bits all in 0
assign numbers1_2[7:4] = 10;                //7 segment case 10 Display °, at display A1(anod)
assign numbers1_2[3:0] = 11;                //7 segment case 11 Display C, at display A0(anod)

bcd #(.W(13)) bin_bcd (
    .bin(i2c_temperature_number[12:0]),     //sending 13-bits instead of 15-bits, bcs 2-bits are unused
    .bcd(numbers1_2[24:8])                  //using all others anods A2-A7
);

//Instance module from file 7segment.v
segment_7 #(.NUM_DISP(8)) seg7(
    .clk(clk_segment),
    .rst(rst),
    .bcd(numbers1_2),
    .anod(displays),
    .katod(segments)
);

//Instance module from file clk_divider.v
clk_divider #(.DIVIDE(50_000)) clock_segment(
    .input_clk(clk),
    .rst(rst),
    .output_clk(clk_segment)
);
endmodule