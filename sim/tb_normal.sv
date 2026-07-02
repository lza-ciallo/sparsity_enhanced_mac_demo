`timescale 1ns/100ps
`define CLK_PERIOD 10

module tb_normal import sim_pkg::*;;

    logic                   clk         ;
    logic                   rst_n       ;
    logic                   clr         ;
    logic                   shift_en    ;
    logic           [7:0]   shift_num   ;
    logic   signed  [7:0]   act         ;
    logic   signed  [7:0]   wet         ;
    logic   signed  [7:0]   result      ;

    logic   signed  [7:0]   act_dram [MAT_ROW][MAT_LEN] ;
    logic   signed  [7:0]   wet_dram [MAT_LEN][MAT_COL] ;
    logic   signed  [7:0]   out_dram [MAT_ROW][MAT_COL] ;

    mac_cell u_mac_cell (
        .clk            (clk        ),
        .rst_n          (rst_n      ),
        .clr            (clr        ),

        .shift_en       (shift_en   ),
        .shift_num      (shift_num  ),

        .act            (act        ),
        .wet            (wet        ),
        .result         (result     )
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

    int cnt = 0;
    int err = 0;
    int m;
    int k;

    initial begin
        rst_n = 1; clr = 0; shift_en = 0; shift_num = 8'd8;
        @(negedge clk) rst_n = 0;
        @(negedge clk) rst_n = 1;

        repeat (NUM_TESTS) begin
            clr = 0;
            cnt += 1;
            m = $urandom_range(MAT_ROW-1, 0);
            k = $urandom_range(MAT_COL-1, 0);
            $display("Test %0d / %0d: m = %0d, k = %0d", cnt, NUM_TESTS, m, k);

            for (int n = 0; n < MAT_LEN; n = n + 1) begin
                act <= act_dram[m][n];
                wet <= wet_dram[n][k];
                @(negedge clk);
            end

            @(negedge clk);
            @(negedge clk) shift_en = 1;
            @(negedge clk) shift_en = 0;
            if (result !== out_dram[m][k]) begin
                $display("- Error! Result = %0d, Reference = %0d", result, out_dram[m][k]);
                err += 1;
            end
            else begin
                $display("- Pass %0d / %0d", cnt, NUM_TESTS);
            end
            clr = 1;
            @(negedge clk);
        end

        $display("Error rate: %0d / %0d", err, NUM_TESTS);
        $finish(0);
    end

endmodule
