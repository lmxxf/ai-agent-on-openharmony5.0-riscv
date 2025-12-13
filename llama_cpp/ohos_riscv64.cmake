# OpenHarmony RISC-V64 交叉编译工具链文件
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR riscv64)

# OHOS SDK路径
set(OHOS_SDK_ROOT "$ENV{OHOS_SDK_ROOT}")
set(OHOS_SYSROOT "${OHOS_SDK_ROOT}/native/sysroot")
set(OHOS_CLANG_ROOT "$ENV{OHOS_CLANG_ROOT}")

# 编译器
set(CMAKE_C_COMPILER "${OHOS_CLANG_ROOT}/bin/clang")
set(CMAKE_CXX_COMPILER "${OHOS_CLANG_ROOT}/bin/clang++")
set(CMAKE_AR "${OHOS_CLANG_ROOT}/bin/llvm-ar")
set(CMAKE_RANLIB "${OHOS_CLANG_ROOT}/bin/llvm-ranlib")

# Target triple
set(OHOS_TARGET "riscv64-linux-ohos")

# 编译标志
set(CMAKE_C_FLAGS_INIT "--target=${OHOS_TARGET} --sysroot=${OHOS_SYSROOT} -march=rv64gcv -mabi=lp64d")
set(CMAKE_CXX_FLAGS_INIT "--target=${OHOS_TARGET} --sysroot=${OHOS_SYSROOT} -march=rv64gcv -mabi=lp64d")
set(CMAKE_EXE_LINKER_FLAGS_INIT "--target=${OHOS_TARGET} --sysroot=${OHOS_SYSROOT} -fuse-ld=lld")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "--target=${OHOS_TARGET} --sysroot=${OHOS_SYSROOT} -fuse-ld=lld")

# 搜索路径
set(CMAKE_FIND_ROOT_PATH "${OHOS_SYSROOT}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# 库路径
link_directories("${OHOS_SYSROOT}/usr/lib/${OHOS_TARGET}")
