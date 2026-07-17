#!/usr/bin/env bash

# This script requires a case-sensitive file system.
# Otherwise some header files will be lost in the sysroot include folder.

set -e -o pipefail

. "$(dirname "$0")/common.sh"


TARGET=$1
LLVM_PATH=$2
DEFAULT_TARGET="$3"

if [ -z "$TARGET" ]; then
	echo "[ERROR] Target is missing." >&2
	exit 1
fi

SCRIPTS="$(dirname "$0")"
system="$(get_build_machine_type)"
system=${system%%-*}

sudo chown -R $(id -u):$(id -g) clang-cross

# Use Clang runtime (compiler-rt) instead of GCC runtime (libgcc_s)
# https://clang.llvm.org/docs/Toolchain.html#compiler-runtime
case $TARGET in
	arm-*linux-musleabi*|powerpcle-*linux-musl)
		use_compiler_rt=false ;;  # Not supported
	*-gnu*) use_compiler_rt=false ;;  # Incompatible with GNU libc
	*) use_compiler_rt=true ;;
esac

# Install the GNU standard C++ library, only if needed
case $TARGET in
	*-musl*) install_libstdcxx=false ;;
	*) install_libstdcxx=true ;;
esac

# Build musl
case $TARGET in
	*-musl*) build_musl=true ;;
	*) build_musl=false ;;
esac

# Download the GNU libraries/headers if needed
if $install_libstdcxx || ! $use_compiler_rt; then
	sudo rm -rf ${TARGET}
	if [ -f "../${TARGET}.tar.xz" ]; then
		tar -xf "../${TARGET}.tar.xz"
	else
		show_progress_message "Downloading GNU libraries"

		name="linux-x64_${TARGET}.tar.xz"
		url="${CROSS_GNU_URL}/gnu-cross/releases/download/x64-${CROSS_GNU_VER}/${name}"
		wget -O - -nv -T 120 --tries=20 "$url" | tar xJ
	fi
	find ${TARGET} -exec chmod a+w {} \;

	cp -a ${TARGET}/lib/gcc clang-cross/lib/
	rm -rf clang-cross/lib/gcc/${TARGET}/*/{install-tools,plugin}
	if $install_libstdcxx; then
		cp -a ${TARGET}/include clang-cross/
		cp -a ${TARGET}/${TARGET} clang-cross/
		rm -rf clang-cross/${TARGET}/{bin,debug-root,lib}
	fi
fi

if $build_musl; then
	rm -rf "clang-cross/${TARGET}/sysroot/usr/include"
	"${SCRIPTS}/build_headers.sh" "$TARGET"
	"${SCRIPTS}/build_musl.sh" "$TARGET" "$LLVM_PATH" $use_compiler_rt headers
fi

CLANG_ARGS="$(read_target_config "../targets/${TARGET}/config")"
echo
echo "Target configuration: \"${CLANG_ARGS}\""
echo

if $use_compiler_rt; then
	"${SCRIPTS}/build_compiler-rt.sh" "$TARGET" "$LLVM_PATH"
	CLANG_ARGS="--rtlib=compiler-rt
${CLANG_ARGS}"
fi

if $build_musl; then
	rm -rf "clang-cross/${TARGET}/sysroot/usr/lib"
	"${SCRIPTS}/build_musl.sh" "$TARGET" "$LLVM_PATH" $use_compiler_rt
fi

show_progress_message "Finalizing toolchain"

for n in clang:clang clang++:clang++ cpp:clang-cpp; do
	cat > clang-cross/bin/${TARGET}-${n%%:*} <<-EOF
		#!/bin/sh
		exec "\$(dirname "\$0")/${n##*:}" --target=${TARGET} "\$@"
	EOF
	chmod +x clang-cross/bin/${TARGET}-${n%%:*}
	cat > clang-cross/bin/${TARGET}-${n##*:}.cfg <<-EOF
		--target=${TARGET}
		--sysroot=<CFGDIR>/../${TARGET}/sysroot
		${CLANG_ARGS}
	EOF
	if [ "$TARGET" != "$DEFAULT_TARGET" ]; then
		cat > clang-cross/bin/${n##*:}.cfg <<-EOF
			@${TARGET}-${n##*:}.cfg
		EOF
	fi
done
ln -sf ${TARGET}-clang clang-cross/bin/${TARGET}-cc
ln -sf ${TARGET}-clang++ clang-cross/bin/${TARGET}-c++
for n in ar:ar c++filt:cxxfilt nm:nm objcopy:objcopy objdump:objdump \
		ranlib:ranlib size:size strings:strings strip:strip; do
	cat > clang-cross/bin/${TARGET}-${n%%:*} <<-EOF
		#!/bin/sh
		exec "\$(dirname "\$0")/llvm-${n##*:}" "\$@"
	EOF
	chmod +x clang-cross/bin/${TARGET}-${n%%:*}
done
find clang-cross -exec chmod a-w {} \;
