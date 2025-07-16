/*
 * tb_Contrast.sv
 * 测试对比度调整模块的测试平台
 * 
 * 该测试平台使用 AXI Stream 接口模拟输入和输出数据流，
 * 并验证对比度调整模块的功能。
 */

`timescale 1ns / 1ps

module tb_Contrast();

    // 测试参数
    parameter int DATA_WIDTH = 8;
    parameter int FRAME_WIDTH = 640;
    parameter int FRAME_HEIGHT = 512;
    parameter real E = 5;
    parameter real THRESHOLD = 127;
    
    // 时钟和复位信号
    reg clk;
    reg rst_n;
    
    // AXI Stream 接口实例化
    AxiStreamIf #(.DATA_WIDTH(DATA_WIDTH)) s_axis();
    AxiStreamIf #(.DATA_WIDTH(DATA_WIDTH)) m_axis();
    
    // 测试控制信号
    logic test_done;
    logic [31:0] test_count;
    logic [31:0] error_count;
    
    // 实例化被测试模块
    Contrast #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAME_WIDTH(FRAME_WIDTH),
        .FRAME_HEIGHT(FRAME_HEIGHT),
        .E(E),
        .THRESHOLD(THRESHOLD)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .s_axis(s_axis),
        .m_axis(m_axis)
    );
    
    // 时钟生成器 (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // 测试序列
    initial begin
        // 初始化信号
        initialize_signals();
        
        // 复位操作
        reset_dut();
        
        // 开始测试
        $display("=============================================");
        $display("开始对比度调整模块测试");
        $display("参数: DATA_WIDTH=%d, E=%f, THRESHOLD=%f", DATA_WIDTH, E, THRESHOLD);
        $display("=============================================");
        
        // 测试各种场景
        test_single_pixels();
        test_frame_processing();
        test_edge_cases();
        test_random_data();
        
        // 显示测试结果
        $display("=============================================");
        $display("测试完成!");
        $display("总测试数: %d", test_count);
        $display("错误数: %d", error_count);
        if (error_count == 0) begin
            $display("所有测试通过! ✓");
        end else begin
            $display("发现 %d 个错误! ✗", error_count);
        end
        $display("=============================================");
        
        // 完成测试
        #100;
        $finish;
    end
    
    // 初始化信号
    task initialize_signals();
        begin
            rst_n = 0;
            s_axis.tvalid = 0;
            s_axis.tdata = 0;
            s_axis.tlast = 0;
            s_axis.tuser = 0;
            m_axis.tready = 1;
            test_done = 0;
            test_count = 0;
            error_count = 0;
        end
    endtask
    
    // 复位DUT
    task reset_dut();
        begin
            $display("执行复位操作...");
            rst_n = 0;
            repeat(10) @(posedge clk);
            rst_n = 1;
            repeat(5) @(posedge clk);
            $display("复位完成");
        end
    endtask
    
    // 发送单个像素数据
    task send_pixel(input [DATA_WIDTH-1:0] pixel_data, input is_last = 0, input is_user = 0);
        begin
            @(posedge clk);
            s_axis.tdata = pixel_data;
            s_axis.tvalid = 1;
            s_axis.tlast = is_last;
            s_axis.tuser = is_user;
            
            // 等待握手完成
            wait(s_axis.tready);
            @(posedge clk);
            s_axis.tvalid = 0;
            s_axis.tlast = 0;
            s_axis.tuser = 0;
        end
    endtask
    
    // 等待并检查输出
    task check_output(input [DATA_WIDTH-1:0] expected_data, input [DATA_WIDTH-1:0] input_data);
        begin
            wait(m_axis.tvalid);
            @(posedge clk);
            
            test_count++;
            if (m_axis.tdata == expected_data) begin
                $display("PASS: 输入=%3d, 期望=%3d, 实际=%3d", input_data, expected_data, m_axis.tdata);
            end else begin
                $display("FAIL: 输入=%3d, 期望=%3d, 实际=%3d", input_data, expected_data, m_axis.tdata);
                error_count++;
            end
        end
    endtask
    
    // 计算期望的输出值
    function automatic [DATA_WIDTH-1:0] calculate_expected(input [DATA_WIDTH-1:0] input_pixel);
        real temp_var;
        begin
            if (input_pixel == 0) begin
                calculate_expected = 255;
            end else begin
                temp_var = 255.0/((1.0 + THRESHOLD/real'(input_pixel))**E);
                calculate_expected = int'(temp_var);
            end
        end
    endfunction
    
    // 测试单个像素值
    task test_single_pixels();
        logic [DATA_WIDTH-1:0] test_pixels[$];
        logic [DATA_WIDTH-1:0] expected_output;
        int i;
        begin
            $display("\n--- 测试单个像素值 ---");
            
            // 创建测试像素数组
            test_pixels = {0, 1, 16, 32, 64, 96, 127, 128, 160, 192, 224, 255};
            
            foreach(test_pixels[i]) begin
                expected_output = calculate_expected(test_pixels[i]);
                send_pixel(test_pixels[i]);
                check_output(expected_output, test_pixels[i]);
            end
            
            $display("单个像素测试完成\n");
        end
    endtask
    
    // 测试完整帧处理
    task test_frame_processing();
        logic [DATA_WIDTH-1:0] expected_output;
        int pixel_count;
        begin
            $display("\n--- 测试帧处理 ---");
            
            pixel_count = 0;
            
            // 发送一个小帧 (8x8)
            for (int row = 0; row < 8; row++) begin
                for (int col = 0; col < 8; col++) begin
                    logic [DATA_WIDTH-1:0] pixel_value;
                    logic is_last_pixel;
                    
                    pixel_value = (row * 8 + col) % 256;
                    is_last_pixel = (row == 7 && col == 7);
                    pixel_count++;
                    
                    expected_output = calculate_expected(pixel_value);
                    send_pixel(pixel_value, is_last_pixel, (row == 0 && col == 0));
                    check_output(expected_output, pixel_value);
                end
            end
            
            $display("帧处理测试完成 (处理了 %d 个像素)\n", pixel_count);
        end
    endtask
    
    // 测试边界情况
    task test_edge_cases();
        logic [DATA_WIDTH-1:0] expected_output;
        begin
            $display("\n--- 测试边界情况 ---");
            
            // 测试最小值
            expected_output = calculate_expected(0);
            send_pixel(0);
            check_output(expected_output, 0);
            
            // 测试最大值
            expected_output = calculate_expected(255);
            send_pixel(255);
            check_output(expected_output, 255);
            
            // 测试阈值附近的值
            expected_output = calculate_expected(THRESHOLD-1);
            send_pixel(THRESHOLD-1);
            check_output(expected_output, THRESHOLD-1);
            
            expected_output = calculate_expected(THRESHOLD);
            send_pixel(THRESHOLD);
            check_output(expected_output, THRESHOLD);
            
            expected_output = calculate_expected(THRESHOLD+1);
            send_pixel(THRESHOLD+1);
            check_output(expected_output, THRESHOLD+1);
            
            $display("边界情况测试完成\n");
        end
    endtask
    
    // 测试随机数据
    task test_random_data();
        logic [DATA_WIDTH-1:0] random_pixel;
        logic [DATA_WIDTH-1:0] expected_output;
        int i;
        begin
            $display("\n--- 测试随机数据 ---");
            
            for (i = 0; i < 20; i++) begin
                random_pixel = $urandom_range(0, 255);
                expected_output = calculate_expected(random_pixel);
                send_pixel(random_pixel);
                check_output(expected_output, random_pixel);
            end
            
            $display("随机数据测试完成\n");
        end
    endtask
    
    // 监控超时
    initial begin
        #1000000; // 1ms 超时
        $display("ERROR: 测试超时!");
        $finish;
    end
    
    // 监控 AXI Stream 握手
    always @(posedge clk) begin
        if (rst_n && s_axis.tvalid && !s_axis.tready) begin
            $display("WARNING: s_axis.tready 信号为低，可能出现死锁");
        end
        if (rst_n && m_axis.tvalid && !m_axis.tready) begin
            $display("WARNING: m_axis.tready 信号为低，可能出现死锁");
        end
    end
    
endmodule
