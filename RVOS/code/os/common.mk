# Common part for the Makefile.
# This file will be included by the Makefile of each project.

# Custom Macro Definition (Common part)

include ../defines.mk
DEFS +=

# 交叉编译前缀,unknown: 通常表示供应商或系统无关（常见于开源工具链）。

CROSS_COMPILE = riscv64-unknown-elf-
# 编译选项
# -nostdlib：禁止链接标准库（裸机程序常见）。
# -fno-builtin：禁用内置函数优化（避免与自定义实现冲突）。
# -g：生成调试信息。
# -Wall：开启编译器的所有常见警告信息
# -march=rv32g：目标架构为 32 位 RISC-V，支持所有标准扩展（g 表示通用扩展集）。
# -mabi=ilp32：ABI 约定为 32 位整数、长指针（ILP32）。
CFLAGS += -nostdlib -fno-builtin -g -Wall
CFLAGS += -march=rv32g -mabi=ilp32

# 定义仿真器qemu为qemu-system-riscv32
QEMU = qemu-system-riscv32
# 定义QEMU编译选项
# -nographic：让 QEMU 以非图形化模式运行, 将输入输出重定向到终端
# -smp 1：smp 代表对称多处理（Symmetric Multi - Processing），-smp 1 表示模拟的系统中仅使用 1 个 CPU 核心。
# -machine virt:该选项指定了 QEMU 要模拟的机器类型为 virt。
# -bios none：此选项表示不使用 BIOS（基本输入输出系统）。
QFLAGS = -nographic -smp 1 -machine virt -bios none

# 定义GDB、gcc、objdump、objcopy工具
GDB = gdb-multiarch
CC = ${CROSS_COMPILE}gcc
OBJCOPY = ${CROSS_COMPILE}objcopy
OBJDUMP = ${CROSS_COMPILE}objdump

# 定义创建目录，删除目录命令
MKDIR = mkdir -p
RM = rm -rf
# 定义输出路径
OUTPUT_PATH = out

# SRCS_ASM & SRCS_C are defined in the Makefile of each project.
# patsubst:按照模式对文件名进行替换。语法：$(patsubst <pattern>,<replacement>,<text>)
# addprefix：为文件名列表中的每个文件名添加指定的前缀。语法：$(addprefix <prefix>,<names...>)
OBJS_ASM := $(addprefix ${OUTPUT_PATH}/, $(patsubst %.S, %.o, ${SRCS_ASM}))
OBJS_C   := $(addprefix $(OUTPUT_PATH)/, $(patsubst %.c, %.o, ${SRCS_C}))
OBJS = ${OBJS_ASM} ${OBJS_C}

# 指定输出elf和bin文件
ELF = ${OUTPUT_PATH}/os.elf
BIN = ${OUTPUT_PATH}/os.bin

# 根据是否定义 USE_LINKER_SCRIPT 来判断是否使用自定义脚本
USE_LINKER_SCRIPT ?= true
ifeq (${USE_LINKER_SCRIPT}, true)
LDFLAGS = -T ${OUTPUT_PATH}/os.ld.generated
else
LDFLAGS = -Ttext=0x80000000  
endif

# 设置默认目标all
# all依赖文件：1.路径out/ 2.out/os.elf
.DEFAULT_GOAL := all
all: ${OUTPUT_PATH} ${ELF}

# 创建输出文件夹：out/
# @符号是一个特殊的前缀，它的作用是在执行命令时不将命令本身输出到终端，使输出更加简洁。
# $@ 是一个自动化变量，代表当前目标的名称
${OUTPUT_PATH}:
	@${MKDIR} $@

# start.o必须是依赖项中的第一个！
# 对于USE_LINKER_SCRIPT==true，在执行链接之前，手动运行预处理器链接器脚本。
# -E: 仅运行预处理阶段，处理宏定义、头文件包含等，不进行编译和链接。

# -P: 禁止生成 #line 标记（行号信息），避免污染输出文件。链接器脚本不需要调试信息，保留 #line 可能导致语法错误。

# -x c：强制将输入文件视为 C 语言源代码处理，即使文件扩展名不是 .c。
# 链接器脚本（.ld）本身并非 C 代码，但需借用 GCC 的预处理器功能解析 #ifdef #include 等指令。

# ${OBJS}是当前文件夹中所有.S和.c文件转换成的.o文件
${ELF}: ${OBJS}
ifeq (${USE_LINKER_SCRIPT}, true)
	${CC} -E -P -x c ${DEFS} ${CFLAGS} os.ld > ${OUTPUT_PATH}/os.ld.generated
endif
	${CC} ${CFLAGS} ${LDFLAGS} -o ${ELF} $^
	${OBJCOPY} -O binary ${ELF} ${BIN}

${OUTPUT_PATH}/%.o : %.c
	${CC} ${DEFS} ${CFLAGS} -c -o $@ $<

${OUTPUT_PATH}/%.o : %.S
	${CC} ${DEFS} ${CFLAGS} -c -o $@ $<

run: all
	${QEMU} -M help | grep virt >/dev/null || exit
	@echo "Press Ctrl-A and then X to exit QEMU"
	@echo "------------------------------------"
	${QEMU} ${QFLAGS} -kernel ${ELF}

.PHONY : debug
debug: all
	@echo "Press Ctrl-C and then input 'quit' to exit GDB and QEMU"
	@echo "-------------------------------------------------------"
	${QEMU} ${QFLAGS} -kernel ${ELF} -gdb tcp::5555 -S &
	${GDB} ${ELF} -q -x ../gdbinit

.PHONY : code
code: all
	@${OBJDUMP} -S ${ELF} | less

.PHONY : clean
clean:
	@${RM} ${OUTPUT_PATH}
