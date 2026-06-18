module segment_7 #(parameter NUM_DISP = 8)(
    //Inputs
    input wire clk,
    input wire rst,
    input wire [NUM_DISP*4-1:0] bcd,

    //Outputs
    output reg [NUM_DISP-1:0] anod,
    output reg [7:0] katod
);

reg [$clog2(NUM_DISP)-1:0] number_anod;
reg [3:0] active_bcd;

always @(negedge clk or posedge rst) begin
    if(rst) begin                                                     
        number_anod <= 1'b0;                                            
    end else begin
        if(number_anod == NUM_DISP - 1) begin                                     
           number_anod <= 1'b0;                              
        end else begin
           number_anod <= number_anod + 1'b1; 
        end
    end
end

always @(*) begin
    active_bcd = 1'b0;                      //binary null
    anod = ~(1 << number_anod);             //activate the current one anode
    active_bcd = bcd >> (number_anod * 4);  //shift 4-bits to the right for the current one anode
    case (active_bcd)                  
        0 : katod = 8'b00000011;        // Display 0
        1 : katod = 8'b10011111;        // Display 1
        2 : katod = 8'b00100101;        // Display 2
        3 : katod = 8'b00001101;        // Display 3
        4 : katod = 8'b10011001;        // Display 4
        5 : katod = 8'b01001001;        // Display 5
        6 : katod = 8'b01000001;        // Display 6
        7 : katod = 8'b00011111;        // Display 7
        8 : katod = 8'b00000001;        // Display 8
        9 : katod = 8'b00001001;        // Display 9
        10 : katod = 8'b00111001;       // Display °
        11 : katod = 8'b01100011;       // Display C
        default: katod = 8'b11111111;   // Empty Display
    endcase
    if(number_anod == 4) begin
        katod[0] = 1'b0;                    //Display dot
    end else begin
        katod[0] = 1'b1;
    end
end
endmodule