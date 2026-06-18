module clk_divider #(parameter DIVIDE = 100_000_000)(
    //Inputs
    input wire input_clk,       
    input wire rst,

    //Outputs
    output wire output_clk                            //wire bcs of assign
);

localparam WIDTH = $clog2(DIVIDE);                          //$clog2 cover range of numbers DIVIDE
localparam DIVIDE_MINUS_ONE = DIVIDE - 1;

reg [WIDTH-1:0] counter;

assign output_clk = counter[WIDTH-1];                      //assign counter param number to output_clk, MSB

always @(negedge input_clk or posedge rst) begin
    if(rst) begin                                           
        counter <= {(WIDTH){1'b0}};                         //reset counter,binary null
    end else begin
        if(counter == DIVIDE_MINUS_ONE[WIDTH-1:0]) begin    //if counter MAX number
           counter <= {(WIDTH){1'b0}};                      //binary null
        end else begin
            counter <= counter + 1'b1;                      
        end
    end
end
endmodule