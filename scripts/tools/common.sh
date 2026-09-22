#!/usr/bin/env bash

CROSS_GNU_URL="https://github.com/Matrix3600"
CROSS_GNU_VER="20260908"
CROSS_MUSL_URL="https://github.com/Matrix3600"
CROSS_MUSL_VER="20260908"
CROSS_CLANG_URL="https://github.com/Matrix3600"
CROSS_CLANG_VER="20260922"
CROSS_CLANG_RESUME="false"
CROSS_CLANG_LATEST="latest-llvm-builds"

LINUX_URL="https://www.kernel.org/pub/linux/kernel/v6.x/linux-6.1.188.tar.xz"
LINUX_SHA256="ed4d0acb1307c235230c89efc094e210e6290593f94a7e617f28b1001101a33a"

MUSL_URL="https://musl.libc.org/releases https://sources.buildroot.net/musl"
MUSL_VER="1.2.6"
MUSL_SHA256="d585fd3b613c66151fc3249e8ed44f77020cb5e6c1e635a616d3f9f82460512a"

#
# LLVM build compilers for canadian builds (make_canadian)
#

LLVM_URL="https://github.com/llvm"
LLVM_VER="23.1.2"
# LLVM-${LLVM_VER}-Linux-X64.tar.xz
LLVM_X64_SHA256="b5ed9675149cc837c282e9b6962c276c9fa62863d5b2f91537b60848552995b7"
# LLVM-${LLVM_VER}-Linux-ARM64.tar.xz
LLVM_ARM64_SHA256="075da47cb832273717d4c7bad4b6b4848d7c154262e9ba0dcc0025426d4073f0"

LLVM_MINGW_URL="https://github.com/mstorsjo"
LLVM_MINGW_VER="20260922"
LLVM_MINGW_UBNT_VER="22.04"
# llvm-mingw-${LLVM_MINGW_VER}-msvcrt-ubuntu-${LLVM_MINGW_UBNT_VER}-x86_64.tar.xz
LLVM_MINGW_X64_SHA256="17bbc667b96f7b1f02ce4a172d8cac4fa480927a1f649e788dee5914919566a1"
# llvm-mingw-${LLVM_MINGW_VER}-ucrt-ubuntu-${LLVM_MINGW_UBNT_VER}-aarch64.tar.xz
LLVM_MINGW_ARM64_SHA256="07d21263c56bfe9a713db6fdb3f7434bf4c121a005e40397d3b4c0170fb06769"


function check_sha256()
{
	local FILENAME="$1"
	local SHA256="$2"
	local chksum
	chksum="$(sha256sum "$FILENAME")"
	chksum="${chksum%%[[:space:]]*}"

	if [ "$chksum" != "$SHA256" ]; then
		echo "[ERROR] Bad SHA256 for ${FILENAME}: ${chksum}, expected ${SHA256}." >&2
		return 1
	fi
	# echo "[DEBUG] Correct SHA256 for ${FILENAME} (${chksum})."
	return 0
}


function get_build_machine_type()
{
	if [ "$OS" == "Windows_NT" ]; then
		local system="win"
	else
		local system="linux"
		case $(uname -s) in
			Linux) ;;
			Darwin) system="macos" ;;
			*) echo "uname -s: \"$(uname -s)\"" >&2 ;;
		esac
	fi
	local arch="unknown"
	case $(uname -m) in
		i?86) arch="x86" ;;
		x86_64|amd64) arch="x64" ;;
		aarch64*|arm64|armv8*) arch="arm64" ;;
		*) echo "uname -m: \"$(uname -m)\"" >&2 ;;
	esac
	printf '%s\n' "${system}-${arch}"
}


function get_host_type()
{
	local HOST="$1"

	local host_type
	host_type="$(sed 's/-unknown//g' <<< "$HOST")"
	case $host_type in
		aarch64-linux-gnu)
			host_type="linux-arm64" ;;
		aarch64-w64-mingw32)
			host_type="win-arm64" ;;
		riscv64-linux-gnu)
			host_type="linux-riscv64" ;;
		x86_64-linux-gnu)
			host_type="linux-x64" ;;
		x86_64-w64-mingw32)
			host_type="win-x64" ;;
	esac
	printf '%s\n' "$host_type"
}


function get_latest_exec_path
{
	local EXEC_NAME="$1"

	# Search latest executable in PATH
	local exec_path=""
	IFS=:
	for p in $PATH; do
		unset IFS
		local version=0
		for name in ${p}/${EXEC_NAME}*; do
			if [[ -f $name && $name =~ /${EXEC_NAME}(|-([0-9]+))$ ]]; then
				echo "$name" >&2
				local v=${BASH_REMATCH[2]}
				if [ -z "$v" ]; then v=1; fi
				if [[ $v -gt $version ]]; then
					exec_path=$name
					version=$v
				fi
			fi
		done
		if [ -n "$exec_path" ]; then break; fi
	done
	unset IFS
	if [ -n "$exec_path" ]; then
		printf '%s\n' "$exec_path"
		echo "Using $exec_path" >&2
	else
		echo "[ERROR] ${EXEC_NAME} not found." >&2
		return 1
	fi
}


function get_llvm_version()
{
	local ROOT_PATH="$1"
	if [ -z "$ROOT_PATH" ]; then ROOT_PATH="."; fi
	local version_file="${ROOT_PATH}/llvm/cmake/Modules/LLVMVersion.cmake"
	local major="0"
	local minor="0"
	local patch="0"
	local suffix=""
	while IFS= read -r line <&3
	do
		if [ -n "$line" ]; then
			if [[ $line =~ set\(LLVM_VERSION_MAJOR[[:space:]]([0-9]+)\) ]]; then
				major="${BASH_REMATCH[1]}"
			elif [[ $line =~ set\(LLVM_VERSION_MINOR[[:space:]]([0-9]+)\) ]]; then
				minor="${BASH_REMATCH[1]}"
			elif [[ $line =~ set\(LLVM_VERSION_PATCH[[:space:]]([0-9]+)\) ]]; then
				patch="${BASH_REMATCH[1]}"
			elif [[ $line =~ set\(LLVM_VERSION_SUFFIX[[:space:]]([[:alnum:].-]+)\) ]]; then
				suffix="${BASH_REMATCH[1]}"
			fi
		fi
	done 3< "$version_file"
	printf '%s\n' "${major}.${minor}.${patch}${suffix}"
}


function read_target_config
{
	local config_file="$1"
	while IFS= read -r line <&3
	do
		if [ -n "$line" ]; then
			if [[ $line =~ ^[[:space:]]*CLANG_ARGS=\"(.*)\"[[:space:]]*$ ]]; then
				printf '%s\n' "${BASH_REMATCH[1]}"
			fi
		fi
	done 3< "$config_file"
}


function show_progress_message()
{
	echo
	echo "***"
	echo "*** $1"
	echo "***"
	echo
}
