#!/usr/bin/env bash

set -e -o pipefail

. "$(dirname "$0")/common.sh"


TARGET=$1
LLVM_PATH=$2
USE_COMPILER_RT=$3
OPTIONS=$4

if [ -z "$TARGET" ]; then
	echo "[ERROR] Target is missing." >&2
	exit 1
fi

if [ ! -d "$CROSS_CLANG_TARGET_SOURCE_DIR" ]; then
	echo "[ERROR] Source directory invalid (${CROSS_CLANG_TARGET_SOURCE_DIR})." >&2
	exit 1
fi

install_headers=false
if [ "$OPTIONS" == "headers" ]; then
	install_headers=true
fi

if [ ! -f musl/Makefile ]; then
	src_dir="$CROSS_CLANG_TARGET_SOURCE_DIR"
	musl_tarname=musl-${MUSL_VER}.tar.gz
	if [ ! -f "${src_dir}/${musl_tarname}" ]; then
		show_progress_message "Downloading musl ${MUSL_VER}"
		url="${MUSL_URL}/${musl_tarname}"
		wget -nv -nc -T 120 --tries=20 "$url"
		check_sha256 "$musl_tarname" "$MUSL_SHA256"
		mv "$musl_tarname" "${src_dir}/"
	fi
	rm -rf "musl-${MUSL_VER}"
	tar -xf "${src_dir}/${musl_tarname}"
	mv "musl-${MUSL_VER}/" "musl/"

	# Patch
	pushd "musl" >/dev/null
	if [ -d "../../patches/musl/${MUSL_VER}" ]; then

		show_progress_message "Patching musl ${MUSL_VER}"

		find "../../patches/musl/${MUSL_VER}" -type f -name "*.patch" -print0 | \
			sort -z | \
			while IFS= read -r -d '' file; do
				echo "*** ${file#../../patches/}"
				patch -Np1 -i "$file"
			done
	fi
	popd >/dev/null
fi

SYSROOT="$(pwd)/clang-cross/${TARGET}/sysroot"
HOST_LIB_DIR="$(pwd)/clang-cross/lib"
CLANG_ARGS="$(read_target_config "../targets/${TARGET}/config")"
musl_dir="$(pwd)/musl"

if [ ! -d "build-libc" ]; then
	sudo find "clang-cross" -exec chmod a+w {} \;

	cat <<-EOF > "clang-cross/bin/clang.cfg"
		--target=${TARGET}
		--rtlib=compiler-rt
	EOF

	mkdir -p "build-libc"
fi

pushd "build-libc"

if [[ ! -f "config.mak" || \
		! -f "${SYSROOT}/usr/include/bits/alltypes.h" ]]; then

	show_progress_message "Configuring musl ${MUSL_VER}"

	CFLAGS="$CLANG_ARGS"
	LDFLAGS=""
	if [ -z "$LLVM_PATH" ]; then
		CC="clang --target=${TARGET}"
		AR="$(get_latest_exec_path llvm-ar)"
		RANLIB="$(get_latest_exec_path llvm-ranlib)"
		CFLAGS="${CFLAGS} -fuse-ld=lld"

		rt_lib_dir=""
		if [ "$USE_COMPILER_RT" == true ]; then
			CFLAGS="--rtlib=compiler-rt ${CFLAGS}"
			clang_lib_dir="${HOST_LIB_DIR}/clang"
			pushd "$clang_lib_dir" >/dev/null
			for version in *; do
				if [[ -d $version && $version =~ ^[1-9][0-9]*$ ]]; then
					rt_lib_dir="${clang_lib_dir}/${version}/lib/${TARGET}"
				fi
			done
			popd >/dev/null
		else
			gcc_lib_dir="${HOST_LIB_DIR}/gcc/${TARGET}"
			pushd "$gcc_lib_dir" >/dev/null
			for version in *; do
				if [[ -d $version && $version =~ ^[1-9][0-9.]*$ ]]; then
					rt_lib_dir="${gcc_lib_dir}/${version}"
				fi
			done
			popd >/dev/null
		fi
		if [ -n "$rt_lib_dir" ]; then
			LDFLAGS="-L\"$rt_lib_dir\" ${LDFLAGS}"
		fi
	else
		CC="${LLVM_PATH}/clang"
		AR="${LLVM_PATH}/llvm-ar"
		RANLIB="${LLVM_PATH}/llvm-ranlib"
	fi
	if [ "$USE_COMPILER_RT" == true ]; then
		libcc="-lclang_rt.builtins"
	else
		libcc="-lgcc -lgcc_eh"
	fi

	"${musl_dir}/configure" --target=$TARGET --disable-wrapper \
		--prefix="${SYSROOT}/usr" --syslibdir="${SYSROOT}/lib" \
		--enable-optimize=size \
		CC="$CC" \
		AR="$AR" \
		RANLIB="$RANLIB" \
		LIBCC="$libcc" \
		CFLAGS="${CFLAGS}" \
		LDFLAGS="$LDFLAGS"

	show_progress_message "Installing musl headers"

	make install-headers
fi

if ! $install_headers; then

	show_progress_message "Building musl ${MUSL_VER}"

	make install

	# Convert the absolute symbolic link to a relative link
	pushd "${SYSROOT}/lib" >/dev/null
	for linkname in ld-musl-*.so.* ; do
		if [ -L "$linkname" ]; then
			# Note: ln -r doesn't work on macOS
			ln -sf "../usr/lib/libc.so" "$linkname"
		fi
	done
	popd >/dev/null

	rm -f "../clang-cross/bin/clang.cfg"
fi

popd
