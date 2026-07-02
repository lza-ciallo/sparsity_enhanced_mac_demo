module sparse_core #(
    parameter       BW_ACT          =       8                   ,
    parameter       BW_ACCU         =       32                  ,
    parameter       BUF_DEPTH       =       16
)(
    input   logic                           clk                 ,
    input   logic                           rst_n               ,
    input   logic                           clr                 ,

    input   logic                           shift_en            ,
    input   logic           [BW_ACT-1:0]    shift_num           ,

    input   logic   signed  [BW_ACT-1:0]    act_unpacked [4]    ,
    input   logic   signed  [BW_ACT-1:0]    wet_unpacked [4]    ,

    output  logic                           full_warning        ,
    output  logic   signed  [BW_ACT-1:0]    result
);

    logic   signed  [BW_ACT-1:0]    act_packed [4]  ;
    logic   signed  [BW_ACT-1:0]    wet_packed [4]  ;
    logic           [3:0]           mask_packed     ;

    logic   signed  [BW_ACT-1:0]    act_out         ;
    logic   signed  [BW_ACT-1:0]    wet_out         ;

    sparse_filter #(
        .BW_ACT         (BW_ACT         )
    ) u_sparse_filter (
        .clk            (clk            ),
        .rst_n          (rst_n          ),
        .act_unpacked   (act_unpacked   ),
        .wet_unpacked   (wet_unpacked   ),
        .act_packed     (act_packed     ),
        .wet_packed     (wet_packed     ),
        .mask_packed    (mask_packed    )
    );

    sparse_buffer #(
        .BW_ACT         (BW_ACT         ),
        .BUF_DEPTH      (BUF_DEPTH      )
    ) u_sparse_buffer (
        .clk            (clk            ),
        .rst_n          (rst_n          ),
        .act_packed     (act_packed     ),
        .wet_packed     (wet_packed     ),
        .mask_packed    (mask_packed    ),
        .act_out        (act_out        ),
        .wet_out        (wet_out        ),
        .full_warning   (full_warning   )
    );

    mac_cell #(
        .BW_ACT         (BW_ACT         ),
        .BW_ACCU        (BW_ACCU        )
    ) u_mac_cell (       
        .clk            (clk            ),
        .rst_n          (rst_n          ),
        .clr            (clr            ),

        .shift_en       (shift_en       ),
        .shift_num      (shift_num      ),

        .act            (act_out        ),
        .wet            (wet_out        ),
        .result         (result         )
    );

endmodule
