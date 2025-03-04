# Note: The Makefile for each project is just a symbol-link to the build.mk
#       under the "asm" folder.

# 定义可执行文件名
EXEC = test

# 定义源文件名，${}表示引用变量
SRC = ${EXEC}.s

# 定义GDB初始化文件的路径
GDBINIT = ../gdbinit

# 引用上级目录的rule.mk文件
include ../rule.mk
