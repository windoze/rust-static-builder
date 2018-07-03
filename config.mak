GNU_SITE = https://mirrors.ustc.edu.cn/gnu
LINUX_SITE = http://mirrors.ustc.edu.cn/kernel.org/linux/kernel
TARGET = x86_64-linux-musl
OUTPUT = /opt/cross
DL_CMD = curl -C - -L -o
COMMON_CONFIG += CC="gcc -static --static -fPIC" CXX="g++ -static --static -fPIC"
GCC_CONFIG += --enable-languages=c,c++
GCC_CONFIG += --disable-multilib
COMMON_CONFIG += --disable-shared
MUSL_CONFIG += --disable-shared
