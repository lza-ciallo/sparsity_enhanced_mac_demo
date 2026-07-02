module sparse_buffer #(
    parameter   BW_ACT      =       8                       ,
    parameter   BUF_DEPTH   =       16
)(
    input   logic                           clk             ,
    input   logic                           rst_n           ,
    input   logic   signed  [BW_ACT-1:0]    act_packed [4]  ,
    input   logic   signed  [BW_ACT-1:0]    wet_packed [4]  ,
    input   logic           [3:0]           mask_packed     ,
    output  logic   signed  [BW_ACT-1:0]    act_out         ,
    output  logic   signed  [BW_ACT-1:0]    wet_out         ,
    output  logic                           full_warning
);

    typedef struct packed {
        logic   signed  [BW_ACT-1:0]    act     ;
        logic   signed  [BW_ACT-1:0]    wet     ;
    } fifo_t;

    fifo_t  [BUF_DEPTH-1:0]         fifo        ;
    logic   [$clog2(BUF_DEPTH)-1:0] ptr_old     ;
    logic   [$clog2(BUF_DEPTH)-1:0] ptr_young   ;

    logic   [$clog2(BUF_DEPTH)-1:0] ptr_young1  ;
    logic   [$clog2(BUF_DEPTH)-1:0] ptr_young2  ;
    logic   [$clog2(BUF_DEPTH)-1:0] ptr_young3  ;
    logic   [$clog2(BUF_DEPTH)-1:0] ptr_young4  ;

    // generate ptr_young's for fifo renew
    always_comb begin
        ptr_young1 = ptr_young + 1;
        ptr_young2 = ptr_young + 2;
        ptr_young3 = ptr_young + 3;
        ptr_young4 = ptr_young + 4;
    end

    // generate full_warning signal
    always_comb begin
        if (ptr_old > ptr_young) begin
            full_warning = (ptr_old - ptr_young < 5);
        end
        else begin
            full_warning = (BUF_DEPTH - ptr_young + ptr_old < 5);
        end
    end

    // fifo operation
    always_ff @( posedge clk or negedge rst_n ) begin
        if (~rst_n) begin
            fifo        <=  '{default: '0}  ;
            ptr_old     <=  '0              ;
            ptr_young   <=  '0              ;
        end
        else begin
            // PUSH IN new data & RENEW ptr_young
            if (mask_packed != 0 && full_warning != 1) begin
                case (mask_packed)
                    4'b0001: begin
                        fifo[ptr_young]     <=  {act_packed[0], wet_packed[0]};
                        ptr_young           <=  ptr_young1;
                    end
                    4'b0011: begin
                        fifo[ptr_young]     <=  {act_packed[0], wet_packed[0]};
                        fifo[ptr_young1]    <=  {act_packed[1], wet_packed[1]};
                        ptr_young           <=  ptr_young2;
                    end
                    4'b0111: begin
                        fifo[ptr_young]     <=  {act_packed[0], wet_packed[0]};
                        fifo[ptr_young1]    <=  {act_packed[1], wet_packed[1]};
                        fifo[ptr_young2]    <=  {act_packed[2], wet_packed[2]};
                        ptr_young           <=  ptr_young3;
                    end
                    4'b1111: begin
                        fifo[ptr_young]     <=  {act_packed[0], wet_packed[0]};
                        fifo[ptr_young1]    <=  {act_packed[1], wet_packed[1]};
                        fifo[ptr_young2]    <=  {act_packed[2], wet_packed[2]};
                        fifo[ptr_young3]    <=  {act_packed[3], wet_packed[3]};
                        ptr_young           <=  ptr_young4;
                    end
                    default: ptr_young      <=  ptr_young;
                endcase
            end
            // POP OUT old data & RENEW ptr_old
            if (ptr_old != ptr_young) begin
                fifo[ptr_old]   <=  '0;
                ptr_old         <=  ptr_old + 1;
            end
        end
    end

    // read data
    always_comb begin
        {act_out, wet_out} = fifo[ptr_old];
    end

endmodule
