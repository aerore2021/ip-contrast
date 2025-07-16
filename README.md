# IP-Contrast: 对比度调整IP核

一个用于图像对比度调整的 SystemVerilog IP 核，采用 AXI Stream 接口设计。

## 📋 项目概述

本项目实现了一个基于查找表（LUT）的对比度调整算法，通过预计算的方式提供高效的像素级对比度调整功能。IP核采用标准的 AXI4-Stream 接口，便于集成到各种视频处理管道中。

### 🎯 主要特性

- **高性能**: 基于 BRAM 查找表实现，支持每时钟周期处理一个像素
- **可配置**: 支持可调节的对比度参数（E 和 THRESHOLD）
- **标准接口**: 完整的 AXI4-Stream 接口实现
- **模块化设计**: 清晰的接口定义和模块化架构
- **自动化构建**: 提供完整的 TCL 脚本和 Shell 脚本支持

## 📁 项目结构

```
ip-Contrast/
├── src/                        # 源代码目录
│   ├── Contrast.sv            # 主要的对比度调整模块
│   └── AxiStreamIf.sv         # AXI Stream 接口定义
├── sim/                       # 仿真文件目录
│   └── tb_Contrast.sv         # 测试平台文件
├── constraints/               # 约束文件目录
│   └── constraints.xdc        # 时序约束文件
├── scripts/                   # 构建脚本目录
│   ├── make.tcl              # 项目创建脚本
│   ├── syn.tcl               # 综合脚本
│   ├── sim.tcl               # 仿真脚本
│   └── run.sh                # 一键构建脚本
├── ContrastAdjust_project/    # Vivado 项目目录
└── README.md                 # 项目说明文档
```

## 🛠️ 快速开始

### 环境要求

- **Vivado**: 2021.1 或更高版本
- **操作系统**: Windows 10/11 

### 🚀 一键构建

项目提供了灵活的构建脚本，支持多种构建选项：

```bash
# 只创建项目
./run.sh

# 创建项目并运行综合
./run.sh -s

# 创建项目并运行仿真
./run.sh -sim

# 运行所有步骤（综合 + 仿真）
./run.sh -a

# 显示帮助信息
./run.sh -h
```

### 📋 构建选项

| 选项 | 描述 |
|------|------|
| `-s, --synthesis` | 在项目创建后运行综合 |
| `-sim, --simulation` | 运行仿真 |
| `-a, --all` | 运行所有步骤（综合 + 仿真） |
| `-h, --help` | 显示帮助信息 |

### 🔧 手动构建

如果您需要手动控制构建过程：

```bash
# 1. 创建项目
vivado -mode tcl -source make.tcl

# 2. 运行综合（可选）
vivado -mode tcl -source syn.tcl

# 3. 运行仿真（可选）
vivado -mode tcl -source sim.tcl
```

## 📊 模块详细信息

### Contrast 模块

**功能描述**: 实现基于查找表的对比度调整算法

**参数配置**:
```systemverilog
parameter int DATA_WIDTH = 8;          // 数据位宽
parameter int FRAME_WIDTH = 640;       // 帧宽度
parameter int FRAME_HEIGHT = 512;      // 帧高度
parameter real E = 5;                  // 对比度指数
parameter real THRESHOLD = 127;        // 对比度阈值
```

**端口定义**:
```systemverilog
module Contrast #(
    parameter int DATA_WIDTH = 8,
    parameter int FRAME_WIDTH = 640,
    parameter int FRAME_HEIGHT = 512,
    parameter real E = 5,
    parameter real THRESHOLD = 127
) (
    input clk,                  // 时钟信号
    input rst_n,                // 复位信号（低电平有效）
    AxiStreamIf.Slave s_axis,   // AXI Stream 从接口
    AxiStreamIf.Master m_axis   // AXI Stream 主接口
);
```

**算法实现**:
对比度调整算法基于以下公式：
```
output = 255 / ((1 + THRESHOLD/input)^E)
```

### AXI Stream 接口

**接口信号**:
- `tvalid`: 数据有效信号
- `tready`: 数据准备就绪信号
- `tdata`: 数据信号
- `tlast`: 帧结束信号
- `tuser`: 帧开始信号
- `tkeep`: 字节使能信号
- `tstrb`: 字节选通信号
- `tdest`: 目标路由信号
- `tid`: 传输ID信号

## 🧪 仿真和验证

### 测试平台特性

测试平台 `tb_Contrast.sv` 提供了全面的验证功能：

- **自动化测试**: 自动生成测试向量和期望结果
- **多场景覆盖**: 包括单像素、完整帧、边界情况和随机数据测试
- **结果验证**: 自动比较实际输出与期望输出
- **错误统计**: 提供详细的测试统计信息

### 运行仿真

```bash
# 运行仿真
./run.sh -sim

# 或者手动运行
vivado -mode tcl -source sim.tcl
```

## ⚡ 性能指标

### 资源使用情况

基于 Xilinx Artix-7 (xc7a100tcsg324-1) 的综合结果：

| 资源类型 | 使用量 | 百分比 |
|----------|--------|--------|
| LUT | 26 | < 1% |
| FF | 10 | < 1% |
| BRAM | 1 | < 1% |
| DSP | 0 | 0% |

### 时序性能

- **最大时钟频率**: > 200 MHz
- **延迟**: 1 时钟周期
- **吞吐量**: 每时钟周期 1 像素

## 🔗 集成指南

### AXI Stream 连接

```systemverilog
// 实例化对比度调整模块
Contrast #(
    .DATA_WIDTH(8),
    .FRAME_WIDTH(640),
    .FRAME_HEIGHT(512),
    .E(5.0),
    .THRESHOLD(127.0)
) contrast_inst (
    .clk(clk),
    .rst_n(rst_n),
    .s_axis(input_stream),
    .m_axis(output_stream)
);
```

### 时序约束

项目包含了完整的时序约束文件 `constraints.xdc`：

```tcl
# 时钟约束
create_clock -period 10.0 -name clk -waveform {0.000 5.000} [get_ports clk]

# 时钟不确定性
set_clock_uncertainty -setup 0.1 -hold 0.1 [get_clocks clk]

# 复位路径约束
set_false_path -from [get_ports rst_n] -to [all_registers]
```

## 📈 算法原理

### 对比度调整算法

对比度调整通过以下非线性变换实现：

```
f(x) = 255 / ((1 + T/x)^E)
```

其中：
- `x`: 输入像素值 (0-255)
- `T`: 阈值参数 (THRESHOLD)
- `E`: 对比度指数 (E)
- `f(x)`: 输出像素值 (0-255)

### 查找表实现

为了提高性能，所有可能的输入值对应的输出值在初始化时预先计算并存储在 BRAM 中：

```systemverilog
initial begin   
    for (int input_pixel = 0; input_pixel < BRAM_SIZE; input_pixel++) begin
        if (input_pixel == 0) begin
            bram[input_pixel] = 255; // 避免除零错误
        end else begin
            temp_var = 255.0/((1.0+THRESHOLD/real'(input_pixel))**E);
            bram[input_pixel] = int'(temp_var);
        end
    end
end
```

## 🛡️ 错误处理

### 综合错误处理

- **语法检查**: 自动检查 SystemVerilog 语法
- **约束验证**: 验证时序约束的有效性
- **资源估算**: 检查资源使用情况

### 仿真错误处理

- **协议验证**: 验证 AXI Stream 协议遵从性
- **数据完整性**: 检查数据传输的完整性
- **时序检查**: 验证时序要求

## 📄 许可证

本项目采用 MIT 许可证
## 👥 作者

- **Aero2021** - *初始工作* - [aerore2021](https://github.com/aerore2021)

---

**更新时间**: 2025年7月16日  

如有任何问题或建议，请创建 Issue 或联系项目维护者。
