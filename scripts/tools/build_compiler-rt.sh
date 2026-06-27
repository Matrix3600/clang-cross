#!/usr/bin/env bash

set -e -o pipefail

. "$(dirname "$0")/common.sh"


TARGET=$1
LLVM_PATH=$2

if [ -z "$TARGET" ]; then
	echo "[ERROR] Target is missing." >&2
	exit 1
fi

SYSROOT="$(pwd)/clang-cross/${TARGET}/sysroot"
CLANG_LIB_DIR="$(pwd)/clang-cross/lib/clang"
CLANG_ARGS="$(read_target_config "../targets/${TARGET}/config")"

sudo rm -rf build-compiler-rt
mkdir build-compiler-rt
pushd build-compiler-rt
INSTALL_DIR="$(pwd)/install"

show_progress_message "Configuring LLVM compiler-rt builtins"

if [ -z "$LLVM_PATH" ]; then
	COMPILER_PREFIX=""
	AR="$(get_latest_exec_path llvm-ar)"
	RANLIB="$(get_latest_exec_path llvm-ranlib)"
else
	COMPILER_PREFIX="${LLVM_PATH}/"
	AR="${LLVM_PATH}/llvm-ar"
	RANLIB="${LLVM_PATH}/llvm-ranlib"
fi

cat - <<-EOF >> toolchain.cmake
	set(CMAKE_SYSTEM_NAME Linux)
	set(CMAKE_SYSROOT "${SYSROOT}")
	set(CMAKE_C_COMPILER "${COMPILER_PREFIX}clang")
	set(CMAKE_CXX_COMPILER "${COMPILER_PREFIX}clang++")
	set(CMAKE_AR "${AR}")
	set(CMAKE_RANLIB "${RANLIB}")
	set(CMAKE_C_COMPILER_TARGET ${TARGET})
	set(CMAKE_CXX_COMPILER_TARGET ${TARGET})
	set(CMAKE_ASM_COMPILER_TARGET ${TARGET})
	set(CMAKE_C_FLAGS_INIT "${CLANG_ARGS}")
	set(CMAKE_CXX_FLAGS_INIT "${CLANG_ARGS}")
	set(CMAKE_ASM_FLAGS_INIT "${CLANG_ARGS}")
	set(CMAKE_LINKER_TYPE LLD)
	set(CMAKE_C_COMPILER_WORKS TRUE)
	set(CMAKE_CXX_COMPILER_WORKS TRUE)
	set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
	set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
	set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
	set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
EOF

cmake -G Ninja \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_TOOLCHAIN_FILE="$(pwd)/toolchain.cmake" \
	-DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
	-DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON \
	-DCOMPILER_RT_USE_BUILTINS_LIBRARY=ON \
	-DCOMPILER_RT_BUILD_CRT=ON \
	-DCOMPILER_RT_EXCLUDE_ATOMIC_BUILTIN=OFF \
	-DLLVM_CMAKE_DIR="" \
	../../llvm/compiler-rt/lib/builtins

show_progress_message "Building LLVM compiler-rt builtins"

ninja install

cd "${INSTALL_DIR}/lib/linux"
arch="${TARGET%%-*}"
for f in clang_rt.crtbegin-*.o; do
	mv "$f" clang_rt.crtbegin.o
done
for f in clang_rt.crtend-*.o; do
	mv "$f" clang_rt.crtend.o
done
for t in "" S T; do
	ln -sf clang_rt.crtbegin.o "crtbegin${t}.o"
	ln -sf clang_rt.crtend.o "crtend${t}.o"
done
for f in libclang_rt.builtins-*.a; do
	mv "$f" libclang_rt.builtins.a
done

pushd "$CLANG_LIB_DIR" >/dev/null
for version in *; do
	if [[ -d $version && $version =~ ^[1-9][0-9]*$ ]]; then
		dest_dir="${CLANG_LIB_DIR}/${version}/lib/${TARGET}"
		mkdir -p "$dest_dir"
		cp -a "${INSTALL_DIR}/lib/linux/." "${dest_dir}/"
	fi
done
popd >/dev/null

popd
sudo rm -rf build-compiler-rt
