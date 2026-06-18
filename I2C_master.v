module I2C_master (
    //Inputs
    input wire clk_double,                                      //clock_double negedge
    input wire rst,                                             //rst posedge
    input wire enable,                                          //start(1) transfer, go out of IDLE and go to START

    //Outputs
    output wire [15:0] temperature_number,                      //send temperature number to bcd

    //I/O
    inout wire scl,                                              //I2C master's SCL is bidirect I/O
    inout wire sda                                               //I2C master's SDA is bidirect I/O
);

reg [2:0] state, next_state;                                    //state for FSM
reg [2:0] bit_counter, next_bit_counter;
reg [7:0] raw_temperature_data, next_raw_temperature_data;
reg [11:0] temperature_data_out, next_temperature_data_out;
reg sda_switch;                                                 //to switch between MASTER(0) and SLAVE(1)
reg sda_switch_delay;
reg sda_check;
reg scl_switch;                                                 //scl (0) will copy clock
reg clk;
reg flip_flop, next_flip_flop;                                  //for double read SLAVE_READ

//FSM states
localparam  IDLE = 3'b000;
localparam  START = 3'b001;
localparam  MASTER_WRITE = 3'b010;
localparam  ACK_NACK_W = 3'b011;
localparam  SLAVE_READ = 3'b100;
localparam  ACK_NACK_R = 3'b101;
localparam  STOP = 3'b110;

//Temperature address and R/W bit
localparam  TEMPERATURE_ADDRESS = 8'b0100_1011;                               //temperature address Master -> Slave, datasheet FPGA Nexys A7
localparam  FULL_TEMPERATURE_ADDRESS = {TEMPERATURE_ADDRESS, 1'b1};           //address of temperature sensor + W bit             

//Tri state logic
assign sda = (sda_switch == 0) ? 1'b0 : 1'bz;                                 //1'bz High-impedance so SLAVE take control over SDA, (0) MASTER have control over SDA
assign scl = (scl_switch == 0) ? clk : 1'b1;                                  //scl (0) copy clk, scl (1) will be 1
assign temperature_number = (temperature_data_out * 20'd100) >> 4;            //adjust temperature data *100 for two tens numbers and acording to datasheet shift 4 bits to the right

//Always block for null if rst(1) else for the current and next data(negedge clk) to be wrote
always @(negedge clk or posedge rst) begin
    if(rst) begin
        temperature_data_out <= 8'b0;
        bit_counter <= 1'b0;
        flip_flop <= 1'b0;
        state <= IDLE;
    end else begin
        temperature_data_out <= next_temperature_data_out;
        bit_counter <= next_bit_counter;
        flip_flop <= next_flip_flop;
        state <= next_state;
    end
end

//Data that needs to be read at posedge clk
always @(posedge clk or posedge rst) begin
    if(rst) begin
        raw_temperature_data <= 8'b0;
        sda_check <= 1'b1;
    end else begin
        raw_temperature_data <= next_raw_temperature_data;
        sda_check <= sda;                                                  //need to check ACK_NACK_W state value, need to ask how was value
    end
end

//Intern clk for double clk at posedge
always @(posedge clk_double or posedge rst) begin
    if(rst) begin
        clk <= 1'b0;
    end else begin
        clk <= ~clk;
    end
end

//Write temperature address at negedge clk_double
always @(negedge clk_double or posedge rst) begin
    if(rst) begin
        sda_switch_delay <= 1'b1;
    end else begin
        sda_switch_delay <= FULL_TEMPERATURE_ADDRESS[7 - bit_counter];
    end
end 

always @(*) begin
    scl_switch = 1'b1;                              //default state
    sda_switch = 1'b1;                              //default state
    next_raw_temperature_data = raw_temperature_data;
    next_temperature_data_out = temperature_data_out;
    next_bit_counter = bit_counter;
    next_flip_flop = flip_flop;
    next_state = state;
    case (state)
        IDLE : begin
            scl_switch = 1'b1;                     //default state
            sda_switch = 1'b1;                     //default state
            if(enable) begin
                next_state = START;
            end else begin
                next_state = IDLE;
            end
        end
        START : begin
            scl_switch = 1'b1;                    //HIGH, hold state, stay in (1)
            sda_switch = 1'b0;                    //LOW, MASTER have control over SDA
            next_state = MASTER_WRITE;
        end
        MASTER_WRITE : begin
            scl_switch = 1'b0;                                        //LOW, then SDA change, copy clk (0)
            sda_switch = sda_switch_delay;                            //MASTER sending temperature address bit after bit + W-bit (1) at clk_double negedge
            if(bit_counter == 7) begin
                next_bit_counter = 1'b0;
                next_state = ACK_NACK_W;
            end else begin
                next_bit_counter = bit_counter + 1'b1;
            end
        end
        ACK_NACK_W : begin
            scl_switch = 1'b0;                         //LOW, then SDA change, copy clk (0)
            sda_switch = 1'b1;                         //HIGH, SLAVE have control over SDA (High-impedance)
            if(sda_check == 1'b0) begin                //check, if everything is ok then go SLAVE_READ
                next_state = SLAVE_READ;
            end else begin                              
                next_state = STOP;
            end
        end
        SLAVE_READ : begin
            scl_switch = 1'b0;                                                      //LOW, then SDA change, copy clk (0)
            sda_switch = 1'b1;                                                      //HIGH, SLAVE have control over SDA (High-impedance)
            next_raw_temperature_data[7 - bit_counter] = sda;                       //sda == SLAVE -> MASTER data, bit after bit, 7 + 1 R/W
            if(bit_counter == 7) begin
                if(flip_flop == 1'b0) begin                                         //flip-flop logic, need to read 2x (2-bajts)
                    next_flip_flop = 1'b1;
                    next_temperature_data_out[11:5] = raw_temperature_data[6:0];    //separate temperature number for upper data
                end else begin
                    next_flip_flop = 1'b0;
                    next_temperature_data_out[4:0] = raw_temperature_data[7:3];     //separate temperature number for under data
                end
                next_bit_counter = 1'b0;
                next_state = ACK_NACK_R;
            end else begin
                next_bit_counter = bit_counter + 1'b1;
            end
        end
        ACK_NACK_R : begin
            scl_switch = 1'b0;                               //LOW, then SDA change, copy clk (0)
            sda_switch = ~flip_flop;                         //go back to SLAVE_READ
            if(flip_flop == 1'b0) begin
                next_state = STOP;
            end else begin
                next_state = SLAVE_READ;
            end
        end
        STOP : begin
            scl_switch = 1'b0;                    //LOW, then SDA change, copy clk (0)
            sda_switch = 1'b0;                    //LOW, MASTER have control over SDA
            next_state = IDLE;
        end
        default: next_state = IDLE;
    endcase
end
endmodule