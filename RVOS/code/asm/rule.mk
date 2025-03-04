# This file will be included by the build.mk.

# 定义交叉编译工具前缀
CROSS_COMPILE = riscv64-unknown-elf-
# 定义编译选项：-nostdlib表示不使用标准库，-fno-builtin表示不使用内建函数 -march=rv32g表示编译为RV32G指令集 -mabi=ilp32表示使用ILP32数据模型 -g表示生成调试信息 -Wall表示显示所有警告
CFLAGS = -nostdlib -fno-builtin -march=rv32g -mabi=ilp32 -g -Wall

# 定义QEMU模拟器
QEMU = qemu-system-riscv32
# 定义QEMU选项：-nographic表示不使用图形界面 -smp 1表示使用一个CPU -machine virt表示使用virt平台 -bios none表示不使用BIOS
QFLAGS = -nographic -smp 1 -machine virt -bios none

# 定义GDB工具，支持多架构的 GDB 调试器来进行调试操作
GDB = gdb-multiarch
# ${CROSS_COMPILE}=riscv64-unknown-elf-
# CC: 编译器 OBJCOPY: 二进制文件转换工具 OBJDUMP: 反汇编工具
CC = ${CROSS_COMPILE}gcc
OBJCOPY = ${CROSS_COMPILE}objcopy
OBJDUMP = ${CROSS_COMPILE}objdump


# 当命令前加上@符号后，Make 将不会输出该命令本身，只输出命令的结果。
.DEFAULT_GOAL := all
all:
	@${CC} ${CFLAGS} ${SRC} -Ttext=0x80000000 -o ${EXEC}.elf
	@${OBJCOPY} -O binary ${EXEC}.elf ${EXEC}.bin

.PHONY : run
run: all
	@echo "Press Ctrl-A and then X to exit QEMU"
	@echo "------------------------------------"
	@echo "No output, please run 'make debug' to see details"
	@${QEMU} ${QFLAGS} -kernel ./${EXEC}.elf

.PHONY : debug
debug: all
	@echo "Press Ctrl-C and then input 'quit' to exit GDB and QEMU"
	@echo "-------------------------------------------------------"
	@${QEMU} ${QFLAGS} -kernel ${EXEC}.elf -gdb tcp::5555 -S &
	@${GDB} ${EXEC}.elf -q -x ${GDBINIT}

.PHONY : code
code: all
	@${OBJDUMP} -S ${EXEC}.elf | less

.PHONY : hex
hex: all
	@hexdump -C ${EXEC}.bin

.PHONY : clean
clean:
	rm -rf *.o *.bin *.elf
