#!/usr/bin/env bash

set -e -o pipefail

. "$(dirname "$0")/common.sh"


install_kernel_headers()
{
	local TARGET="$1"

	local kernel_arch
	case ${TARGET%%-*} in
		aarch64|arm64)  kernel_arch="arm64" ;;
		arm*)           kernel_arch="arm" ;;
		i?86|x86_64)    kernel_arch="x86" ;;
		loongarch*)     kernel_arch="loongarch" ;;
		m68k*)          kernel_arch="m68k" ;;
		microblaze*)    kernel_arch="microblaze" ;;
		mips*)          kernel_arch="mips" ;;
		or*)            kernel_arch="openrisc" ;;
		powerpc*)       kernel_arch="powerpc" ;;
		riscv*)         kernel_arch="riscv" ;;
		s390*)          kernel_arch="s390" ;;
		sh*)            kernel_arch="sh" ;;
		*)
			echo "Target not supported (${TARGET})."
			return 1
		;;
	esac

	mkdir -p "${BUILD_DIR}/build-kernel-headers"

	show_progress_message "Installing kernel headers"

	local system
	system="$(get_build_machine_type)"
	case ${system%%-*} in
		macos)
			# On macOS, some headers required for the installation are missing;
			# we have to provide them.
			CPATH="$(brew --prefix libelf)/include${CPATH:+:}${CPATH}"
			CPATH="$(dirname "$0")/headers:${CPATH}"
			export CPATH
			PATH="$(brew --prefix gnu-sed)/libexec/gnubin:$PATH"
			PATH="$(brew --prefix llvm)/bin:$(brew --prefix lld)/bin:$PATH"
			export PATH
		;;
	esac

	make -C "${BUILD_DIR}/linux" \
		--no-print-directory \
		BASH="$(which bash)" \
		LLVM="y" \
		CROSS_COMPILE="${TARGET}-" \
		O="${BUILD_DIR}/build-kernel-headers" \
		ARCH=${kernel_arch} \
		INSTALL_HDR_PATH="${SYSROOT_DIR}/usr" \
		V=0 \
		headers_install

	# Cleanup
	find "${SYSROOT_DIR}" -type f \
		\(	-name '.install' \
				-o -name '..install.cmd' \
				-o -name '.check' \
				-o -name '..check.cmd' \
		\) \
		-exec rm {} \;
}


TARGET=$1

if [ -z "$TARGET" ]; then
	echo "[ERROR] Target is missing." >&2
	exit 1
fi

if [ ! -d "$CROSS_CLANG_TARGET_SOURCE_DIR" ]; then
	echo "[ERROR] Source directory invalid (${CROSS_CLANG_TARGET_SOURCE_DIR})." >&2
	exit 1
fi

BUILD_DIR="$(pwd)"
SYSROOT_DIR="$(pwd)/clang-cross/${TARGET}/sysroot"

case ${TARGET%%-*} in
	loongarch*)
		url=$LINUX_LOONGARCH_URL
		sha256=$LINUX_LOONGARCH_SHA256
		;;
	*)
		url=$LINUX_URL
		sha256=$LINUX_SHA256
		;;
esac

src_dir="$CROSS_CLANG_TARGET_SOURCE_DIR"
linux_tarname=$(basename "$url")
if [ ! -f "${src_dir}/${linux_tarname}" ]; then
	show_progress_message "Downloading kernel headers"
	wget -nv -nc -T 120 --tries=20 "$url"
	check_sha256 "$linux_tarname" "$sha256"
	mv "$linux_tarname" "${src_dir}/"
fi
name=${linux_tarname%%.tar*}
rm -rf "${name}"
tar -xf "${src_dir}/${linux_tarname}"
mv "${name}/" "linux/"

sudo find "clang-cross" -exec chmod a+w {} \;

install_kernel_headers "$TARGET"

cat <<-EOF > "${SYSROOT_DIR}/usr/include/sgidefs.h"
	#include <asm/sgidefs.h> // Redirected by ct-ng
EOF
