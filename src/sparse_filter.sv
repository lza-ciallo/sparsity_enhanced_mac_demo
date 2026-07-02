module sparse_filter #(
    parameter   BW_ACT      =       8
)(
    input   logic                           clk                 ,
    input   logic                           rst_n               ,
    input   logic   signed  [BW_ACT-1:0]    act_unpacked [4]    ,
    input   logic   signed  [BW_ACT-1:0]    wet_unpacked [4]    ,
    output  logic   signed  [BW_ACT-1:0]    act_packed [4]      ,
    output  logic   signed  [BW_ACT-1:0]    wet_packed [4]      ,
    output  logic           [3:0]           mask_packed
);

    logic   [3:0]   mask_unpacked       ;
    logic   [1:0]   pack_index [4]      ;
    logic   [3:0]   mask_packed_comb    ;

    always_comb begin
        for (int idx = 0; idx < 4; idx = idx + 1) begin
            mask_unpacked[idx] = (act_unpacked[idx] == 0 || wet_unpacked[idx] == 0)? 0 : 1;
        end
    end

    always_comb begin
        pack_index = '{default: '0};
        case (mask_unpacked)
            4'b0000: begin                                                                              mask_packed_comb = 4'b0000; end
            4'b0001: begin pack_index[0] = 0;                                                           mask_packed_comb = 4'b0001; end
            4'b0010: begin pack_index[0] = 1;                                                           mask_packed_comb = 4'b0001; end
            4'b0011: begin pack_index[0] = 0; pack_index[1] = 1;                                        mask_packed_comb = 4'b0011; end
            4'b0100: begin pack_index[0] = 2;                                                           mask_packed_comb = 4'b0001; end
            4'b0101: begin pack_index[0] = 0; pack_index[1] = 2;                                        mask_packed_comb = 4'b0011; end
            4'b0110: begin pack_index[0] = 1; pack_index[1] = 2;                                        mask_packed_comb = 4'b0011; end
            4'b0111: begin pack_index[0] = 0; pack_index[1] = 1; pack_index[2] = 2;                     mask_packed_comb = 4'b0111; end
            4'b1000: begin pack_index[0] = 3;                                                           mask_packed_comb = 4'b0001; end
            4'b1001: begin pack_index[0] = 0; pack_index[1] = 3;                                        mask_packed_comb = 4'b0011; end
            4'b1010: begin pack_index[0] = 1; pack_index[1] = 3;                                        mask_packed_comb = 4'b0011; end
            4'b1011: begin pack_index[0] = 0; pack_index[1] = 1; pack_index[2] = 3;                     mask_packed_comb = 4'b0111; end
            4'b1100: begin pack_index[0] = 2; pack_index[1] = 3;                                        mask_packed_comb = 4'b0011; end
            4'b1101: begin pack_index[0] = 0; pack_index[1] = 2; pack_index[2] = 3;                     mask_packed_comb = 4'b0111; end
            4'b1110: begin pack_index[0] = 1; pack_index[1] = 2; pack_index[2] = 3;                     mask_packed_comb = 4'b0111; end
            4'b1111: begin pack_index[0] = 0; pack_index[1] = 1; pack_index[2] = 2; pack_index[3] = 3;  mask_packed_comb = 4'b1111; end
        endcase
    end

    always_ff @( posedge clk or negedge rst_n ) begin
        if (~rst_n) begin
            act_packed  <=  '{default: '0}  ;
            wet_packed  <=  '{default: '0}  ;
            mask_packed <=  '0              ;
        end
        else begin
            for (int idx = 0; idx < 4; idx = idx + 1) begin
                if (mask_packed_comb[idx] != 0) begin
                    act_packed[idx] <= act_unpacked[pack_index[idx]];
                    wet_packed[idx] <= wet_unpacked[pack_index[idx]];
                end
                else begin
                    act_packed[idx] <= '0;
                    wet_packed[idx] <= '0;
                end
            end
            mask_packed <= mask_packed_comb;
        end
    end

endmodule
