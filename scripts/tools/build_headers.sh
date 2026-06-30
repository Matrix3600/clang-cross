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

	local kernel_path="${SRC_DIR}/linux"

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

	make -C "${kernel_path}" \
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

LINUX_URL="https://www.kernel.org/pub/linux/kernel/v5.x"
case ${TARGET%%-*} in
	loongarch*)
		LINUX_VER=5.19.16
		LINUX_SHA256=a1ebaf667e1059ae2d72aa6374a4d6e2febc0b8ccda6a124687acc2ea961e08d
		;;
	*)
		LINUX_VER=5.4.302
		LINUX_SHA256=ae6a3207f12aa4d6cfb0fa793ec9da4a6fcdfdcb57d869d63d6b77e3a8c1423d
		;;
esac

BUILD_DIR="$(pwd)"
SRC_DIR="$BUILD_DIR"
SYSROOT_DIR="$(pwd)/clang-cross/${TARGET}/sysroot"

linux_tarname=linux-${LINUX_VER}.tar.xz
if [ ! -f "../${linux_tarname}" ]; then
	show_progress_message "Downloading kernel headers"
	url="${LINUX_URL}/${linux_tarname}"
	wget -nv -nc -T 120 --tries=20 "$url"
	check_sha256 "$linux_tarname" "$LINUX_SHA256"
	mv "$linux_tarname" ..
fi
rm -rf "linux-${LINUX_VER}"
tar -xf "../${linux_tarname}"
mv "linux-${LINUX_VER}/" "linux/"

sudo find "clang-cross" -exec chmod a+w {} \;

install_kernel_headers "$TARGET"

cat <<-EOF > "${SYSROOT_DIR}/usr/include/sgidefs.h"
	#include <asm/sgidefs.h> // Redirected by ct-ng
EOF
