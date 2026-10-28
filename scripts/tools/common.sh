#!/usr/bin/env bash

CROSS_GNU_URL="https://github.com/Matrix3600"
CROSS_GNU_VER="20261015"
CROSS_MUSL_URL="https://github.com/Matrix3600"
CROSS_MUSL_VER="20261015"
CROSS_CLANG_URL="https://github.com/Matrix3600"
CROSS_CLANG_VER="20261020"
CROSS_CLANG_RESUME="false"
CROSS_CLANG_LATEST="latest-llvm-builds"

LINUX_VER="6.1.190"
# linux-${version}.tar.xz
LINUX_SHA256="8aa50daca0412a3d0a61a87af3744f39773d40b3132635fb7bc9be652cdb7b0c"

MUSL_URL="https://musl.libc.org/releases https://sources.buildroot.net/musl"
MUSL_VER="1.2.6"
# musl-${MUSL_VER}.tar.gz
MUSL_SHA256="d585fd3b613c66151fc3249e8ed44f77020cb5e6c1e635a616d3f9f82460512a"

#
# LLVM build compilers for canadian builds (make_canadian)
#

LLVM_URL="https://github.com/llvm"
LLVM_VER="23.1.4"
# LLVM-${LLVM_VER}-Linux-X64.tar.zst
LLVM_X64_SHA256="efdd1dbd089b99bfcfcde7b8eb1236163f2e88df5a981cca4f783ec9cb5e0378"
# LLVM-${LLVM_VER}-Linux-ARM64.tar.zst
LLVM_ARM64_SHA256="0975f753e0f9b5f83146a7a2f4678bc143e713496b56520716a4de047a63f99f"

LLVM_MINGW_URL="https://github.com/mstorsjo"
LLVM_MINGW_VER="20261020"
LLVM_MINGW_UBNT_VER="22.04"
# llvm-mingw-${LLVM_MINGW_VER}-ucrt-ubuntu-${LLVM_MINGW_UBNT_VER}-x86_64.tar.xz
LLVM_MINGW_X64_SHA256="55064b60b991a1e1e8090b8c2f84e82b22cfe5903d12c159d65064cf5e8ae335"
# llvm-mingw-${LLVM_MINGW_VER}-ucrt-ubuntu-${LLVM_MINGW_UBNT_VER}-aarch64.tar.xz
LLVM_MINGW_ARM64_SHA256="ca16bb0f4f485876496fa46ad8d353c525eba57d0cf9e9e49ec1738fe4810151"


function download_package()
{
	local dest_dir="$1"
	local mirrors="$2"
	local filename="$3"
	local sha256="$4"
	local display_name="$5"
	if [ ! -f "${dest_dir}/${filename}" ]; then
		if [ "$display_name" != "-" ]; then
			if [ -z "$display_name" ]; then
				display_name=$filename
			fi
			show_progress_message "Downloading ${display_name}"
		fi
		local success=false
		for mirror in $mirrors; do
			echo "From ${mirror}"
			local url="${mirror%/}/${filename}"
			if wget -nv -T 120 --tries=5 -nc --progress=dot:binary -P "$dest_dir" "$url" && \
					check_sha256 "${dest_dir}/${filename}" "$sha256" ; then
				success=true
				break
			fi
		done
		if ! $success; then
			echo "[ERROR] Unable to download ${filename}" >&2
			return 1
		fi
	fi
}


function check_sha256()
{
	local filename="$1"
	local sha256="$2"
	local chksum
	chksum="$(sha256sum "$filename")"
	chksum="${chksum%%[[:space:]]*}"

	if [ "$chksum" != "$sha256" ]; then
		echo "[ERROR] Bad sha256 for ${filename}: ${chksum}, expected ${sha256}." >&2
		return 1
	fi
	# echo "[DEBUG] Correct sha256 for ${filename} (${chksum})."
	return 0
}


function get_mirrors()
{
	local package="$1"
	local version="$2"
	case $package in
		linux)
			case $version in
				[34567].*)
					echo "https://cdn.kernel.org/pub/linux/kernel/v${version%%.*}.x"
					;;
			esac
			;;
	esac
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
	local host="$1"

	local host_type
	host_type="$(sed 's/-unknown//g' <<< "$host")"
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
	local exec_name="$1"

	# Search latest executable in PATH
	local exec_path=""
	IFS=:
	for p in $PATH; do
		unset IFS
		local version=0
		for name in ${p}/${exec_name}*; do
			if [[ -f $name && $name =~ /${exec_name}(|-([0-9]+))$ ]]; then
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
		echo "[ERROR] ${exec_name} not found." >&2
		return 1
	fi
}


function get_llvm_version()
{
	local root_path="$1"
	if [ -z "$root_path" ]; then root_path="."; fi
	local version_file="${root_path}/llvm/cmake/Modules/LLVMVersion.cmake"
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
