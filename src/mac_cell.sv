module mac_cell #(
    parameter       BW_ACT      =       8               ,
    parameter       BW_ACCU     =       32
)(
    input   logic                           clk         ,
    input   logic                           rst_n       ,
    input   logic                           clr         ,

    input   logic                           shift_en    ,
    input   logic           [BW_ACT-1:0]    shift_num   ,

    input   logic   signed  [BW_ACT-1:0]    act         ,
    input   logic   signed  [BW_ACT-1:0]    wet         ,
    output  logic   signed  [BW_ACT-1:0]    result
);

    logic   signed  [BW_ACT-1:0]    act_r   ;
    logic   signed  [BW_ACT-1:0]    wet_r   ;
    logic   signed  [BW_ACCU-1:0]   mul_res ;
    logic   signed  [BW_ACCU-1:0]   psum    ;

    always_comb begin
        result =    (psum > 127)    ?   127     :
                    (psum < -128)   ?   -128    :
                                        psum[BW_ACT-1:0];
    end

    always_ff @( posedge clk or negedge rst_n ) begin
        if (~rst_n) begin
            act_r   <=  '0;
            wet_r   <=  '0;
            mul_res <=  '0;
            psum    <=  '0;
        end
        else begin
            if (clr) begin
                act_r   <=  '0;
                wet_r   <=  '0;
                mul_res <=  '0;
                psum    <=  '0;
            end
            else begin
                act_r   <=  act;
                wet_r   <=  wet;
                mul_res <=  act_r * wet_r;
                if (shift_en) begin
                    psum <= psum >>> shift_num;
                end
                else begin
                    psum <= psum + mul_res;
                end
            end
        end
    end

endmodule
