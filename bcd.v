module bcd #(parameter W = 18)(
    input wire [W-1:0] bin,
    output reg [W+(W-4)/3:0] bcd                                   
);

    integer i;
    integer j;

always @(bin) begin
    for(i = 0; i <= W+(W-4)/3; i = i+1) begin 
        bcd[i] = 0;                                                 // initialize with zeros
        bcd[W-1:0] = bin;                                           // initialize with input vector
    end
    for(i = 0; i <= W-4; i = i+1)                                   // iterate on structure depth
        for(j = 0; j <= i/3; j = j+1)                               // iterate on structure width
            if (bcd[W-i+4*j -: 4] > 4)                              // if > 4
                bcd[W-i+4*j -: 4] = bcd[W-i+4*j -: 4] + 4'd3;       // add 3
end
endmodule