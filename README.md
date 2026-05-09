# SCCPU_SIM_RISCV32
基于RISCV32的单周期CPU设计，使用Verilog语言。  
速通版教程： https://b23.tv/ySQz5pU  
恐龙版详细教程：https://b23.tv/Rliw4tV

## 指令集

你可能被要求实现 37 条指令（例如某试验班）或者 30 条指令。

当前实现 **37 条** RV32I 指令，向下兼容初始版本的 30 条指令：

| 类别 | 指令 | 数量 |
|------|------|------|
| 算术逻辑 | ADD, SUB, SLL, SRL, SRA, SLT, SLTU, AND, OR, XOR, SLLI, SRLI, SRAI | 13 |
| 立即数 | ADDI, ANDI, ORI, XORI, LUI, SLTI, SLTIU, AUIPC | 8 |
| 访存 | LW, SW, LH, LHU, LB, LBU, SH, SB | 8 |
| 分支 | BEQ, BNE, BGE, BGEU, BLT, BLTU | 6 |
| 跳转 | JAL, JALR | 2 |

相比 30 条指令版本，新增了 AUIPC 和字节/半字粒度的访存指令（LH/LHU/LB/LBU/SH/SB），数据存储器支持非字对齐的 byte/halfword 读写，通过 DMType 信号控制访存粒度与符号扩展。

**如果你只需要 30 条指令的版本，简单回退到 `commit 222765d` 即可。**

## 工程架构
### source
这里存放着所有必须的源代码和测试文件，但实际上程序并不靠这里的代码运行。

如果你因为一些原因（如电脑缺乏D:\分区等）并不能一键跑通“如何测试”环节的步骤，可以参考 [Maple师傅的教程](https://oldmaple.top/study/cs_e/) 将里面的代码重新编译并运行。

### project
工程的核心文件夹。储存着所有必须的源代码、测试文件、工程文件以及编译后的项目文件。

## 如何测试
首先下载代码。如果你不想更改任何配置，你应该把下载下来的文件夹重命名为`sccpu_sim`，然后将其放在`D:/codtest/demo`文件夹下。 
使用Modelsim仿真。首先在`./project/rv32_sc_sim.dat`中写入16进制的RISCV32机器码，这可以通过Rars工具进行汇编得到。你的项目也可能提供了类似的`.dat`文件，你可以将其中的内容复制粘贴过来
仿真之后，你可以通过`view->Memory List`选项来查看寄存器和内存的值。其中：
1. `rf`是各个寄存器的值。
2. `dmem`是存储数据的内存的值(即`.data`段)
3. `RAM`是存储代码的内存的值(即`.text`段)

你可以通过`右键->Properties`将数据显示为16进制格式。  
得到数据之后，你可以在Rars中运行相应的汇编代码并比对结果。   

前面提供的 [Maple师傅的教程](https://oldmaple.top/study/cs_e/) 也描述了一种测试方法。条条大路通罗马。

提供了两个测试文件：
- `Test_30_Instr.asm` — 30 条指令的基础测试
- `Test_37_Instr.asm` — 37 条指令的完整测试（当前 `rv32_sc_sim.dat` 对应此版本，你也可以基于 `Test_30_Instr.asm` 生成你的版本，或者回退 commit）

当你用Rars运行我们的程序时，应该注意勾选`Setting->Self-modifying code`，并且通过`Setting->Memory Configuration`设置`Text address at 0`。

### RARS 与 ModelSim 的差异

RARS 默认 `.text` 段起始地址为 `0x3000`，而 ModelSim 仿真中代码从 `0x0000` 开始。因此 AUIPC 指令计算后，RARS 中的值会比 ModelSim 多 `0x3000`，这是正常现象，无需修改代码。

## 访存对齐
RISC-V 规范将非对齐访存的行为交由执行环境（EEI）定义。本设计遵循自然对齐要求：byte 访问任意地址均合法；halfword 访问要求地址为 2 的倍数，word 访问要求地址为 4 的倍数。非对齐的 halfword/word 访问行为未定义（与 Rocket/BOOM 等核心一致），外部程序应避免产生非对齐访存。