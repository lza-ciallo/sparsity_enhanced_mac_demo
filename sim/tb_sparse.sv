`timescale 1ns/100ps
`define CLK_PERIOD 10

module tb_sparse import sim_pkg::*;;

    logic                   clk                 ;
    logic                   rst_n               ;
    logic                   clr                 ;
    logic                   shift_en            ;
    logic           [7:0]   shift_num           ;
    logic   signed  [7:0]   act_unpacked [4]    ;
    logic   signed  [7:0]   wet_unpacked [4]    ;
    logic                   full_warning        ;
    logic   signed  [7:0]   result              ;

    logic   signed  [7:0]   act_dram [MAT_ROW][MAT_LEN] ;
    logic   signed  [7:0]   wet_dram [MAT_LEN][MAT_COL] ;
    logic   signed  [7:0]   out_dram [MAT_ROW][MAT_COL] ;

    sparse_core u_sparse_core (
        .clk                (clk            ),
        .rst_n              (rst_n          ),
        .clr                (clr            ),

        .shift_en           (shift_en       ),
        .shift_num          (shift_num      ),

        .act_unpacked       (act_unpacked   ),
        .wet_unpacked       (wet_unpacked   ),

        .full_warning       (full_warning   ),
        .result             (result         )
    );

    initial begin
        $readmemb(ACT_PATH, act_dram);
        $readmemb(WET_PATH, wet_dram);
        $readmemb(OUT_PATH, out_dram);
    end

    initial begin
        clk = 0;
        forever #(`CLK_PERIOD / 2) clk = ~clk;
    end

    int test_cnt = 0;
    int cal_cnt = 0;
    int err = 0;
    int m;
    int k;

    initial begin
        forever begin
            @(negedge clk);
            case (u_sparse_core.u_sparse_buffer.mask_packed)
                4'b0001: cal_cnt += 1;
                4'b0011: cal_cnt += 2;
                4'b0111: cal_cnt += 3;
                4'b1111: cal_cnt += 4;
                default: cal_cnt += 0;
            endcase
        end
    end

    initial begin
        rst_n = 1; clr = 0; shift_en = 0; shift_num = 8'd8;
        @(negedge clk) rst_n = 0;
        @(negedge clk) rst_n = 1;

        repeat (NUM_TESTS) begin
            clr = 0;
            test_cnt += 1;
            m = $urandom_range(MAT_ROW-1, 0);
            k = $urandom_range(MAT_COL-1, 0);
            $display("Test %0d / %0d: m = %0d, k = %0d", test_cnt, NUM_TESTS, m, k);

            for (int nn = 0; nn < MAT_LEN / 4; nn = nn + 1) begin
                while (full_warning) begin
                    act_unpacked <= '{default: '0};
                    wet_unpacked <= '{default: '0};
                    @(negedge clk);
                end
                act_unpacked[0] <= act_dram[m][nn*4+0];
                act_unpacked[1] <= act_dram[m][nn*4+1];
                act_unpacked[2] <= act_dram[m][nn*4+2];
                act_unpacked[3] <= act_dram[m][nn*4+3];
                wet_unpacked[0] <= wet_dram[nn*4+0][k];
                wet_unpacked[1] <= wet_dram[nn*4+1][k];
                wet_unpacked[2] <= wet_dram[nn*4+2][k];
                wet_unpacked[3] <= wet_dram[nn*4+3][k];
                @(negedge clk);
            end

            act_unpacked <= '{default: '0};
            wet_unpacked <= '{default: '0};
            while (u_sparse_core.u_sparse_buffer.ptr_old !=
                   u_sparse_core.u_sparse_buffer.ptr_young) begin
                @(negedge clk);
            end
            @(negedge clk);
            @(negedge clk);
            @(negedge clk);
            @(negedge clk);
            @(negedge clk) shift_en = 1;
            @(negedge clk) shift_en = 0;
            if (result !== out_dram[m][k]) begin
                $display("- Error! Result = %0d, Reference = %0d", result, out_dram[m][k]);
                err += 1;
            end
            else begin
                $display("- Pass %0d / %0d", test_cnt, NUM_TESTS);
            end
            clr = 1;
            @(negedge clk);
        end

        $display("Error rate: %0d / %0d", err, NUM_TESTS);
        $display("======================================");
        $display("Speedup: %0d / %0d = %0.3f",
                58020, $time, 58020.0 / (1.0 * $time));
        $display("Sparse ratio: 1 - %0d / %0d = %0.3f",
                cal_cnt, MAT_LEN * NUM_TESTS, 1 - (1.0 * cal_cnt) / (MAT_LEN * NUM_TESTS));
        $finish(0);
    end

endmodule
