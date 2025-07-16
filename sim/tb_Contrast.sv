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
    
    AxiStreamIf.Slave s_axis;
    AxiStreamIf.Master m_axis;
    
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
        rst_n = 0;
        s_axis.tvalid = 0;
        s_axis.tdata = 0;
        s_axis.tlast = 0;
        s_axis.tuser = 0;
        
        m_axis.tready = 1; // 假设主设备总是准备好接收数据
        
        // 等待复位
        @(posedge clk);
        rst_n = 1;
        
        // 测试像素序列
        test_pixel_sequence();
        
        // 测试边界值
        test_boundary_values();
        
        // 完成测试
        $finish;
    end
    
    // 测试像素序列的任务
    task test_pixel_sequence();
        integer i;
        begin
            for (i = 0; i < 256; i = i + 32) begin
                @(posedge clk);
                s_axis.tdata = i;
                s_axis.tvalid = 1;
                @(posedge clk);
                s_axis.tvalid = 0;

                // 等待输出有效
                wait(m_axis.tvalid);
                @(posedge clk);
                $display("输入: %d, 对比度: %d, 输出: %d", i, contrast_value, m_axis.tdata);
            end
        end
    endtask
    
    // 测试边界值的任务
    task test_boundary_values();
        begin
            // 测试最小值
            @(posedge clk);
            s_axis.tdata = 0;
            s_axis.tvalid = 1;
            @(posedge clk);
            s_axis.tvalid = 0;
            wait(m_axis.tvalid);
            @(posedge clk);
            $display("边界测试 - 输入: 0, 输出: %d", m_axis.tdata);
            
            // 测试最大值
            @(posedge clk);
            s_axis.tdata = 255;
            s_axis.tvalid = 1;
            @(posedge clk);
            s_axis.tvalid = 0;
            wait(m_axis.tvalid);
            @(posedge clk);
            $display("边界测试 - 输入: 255, 输出: %d", m_axis.tdata);
            
            // 测试中间值
            @(posedge clk);
            s_axis.tdata = 128;
            s_axis.tvalid = 1;
            @(posedge clk);
            s_axis.tvalid = 0;
            wait(m_axis.tvalid);
            @(posedge clk);
            $display("边界测试 - 输入: 128, 输出: %d", m_axis.tdata);
        end
    endtask
    
    
endmodule
