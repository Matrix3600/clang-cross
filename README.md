# clang-cross

This is a simple and lightweight project for making a cross-compilation
toolchain with the Clang compiler, and the GNU or Musl C library.

These [ready-to-use](https://github.com/Matrix3600/clang-cross/releases) toolchains run on:

- Linux x86-64
- Linux ARM64
- Windows x86-64
- Windows ARM64
- macOS ARM64 (Apple Silicon)
- macOS Intel, Linux RISC-V,... (depending on demand)

## Supported targets

| Target                         | Kernel  | Clang  | Libc   |
|--------------------------------|:-------:|:------:|:------:|
| aarch64-unknown-linux-gnu      | 5.4.302 | 22.1.8 | 2.43   |
| aarch64-unknown-linux-musl     | 5.4.302 | 22.1.8 | 1.2.6  |
| arm-unknown-linux-gnueabi      | 5.4.302 | 22.1.8 | 2.43   |
| arm-unknown-linux-gnueabihf    | 5.4.302 | 22.1.8 | 2.43   |
| arm-unknown-linux-musleabi     | 5.4.302 | 22.1.8 | 1.2.6  |
| arm-unknown-linux-musleabihf   | 5.4.302 | 22.1.8 | 1.2.6  |
| armv7-unknown-linux-gnueabi    | 5.4.302 | 22.1.8 | 2.43   |
| armv7-unknown-linux-gnueabihf  | 5.4.302 | 22.1.8 | 2.43   |
| armv7-unknown-linux-musleabi   | 5.4.302 | 22.1.8 | 1.2.6  |
| armv7-unknown-linux-musleabihf | 5.4.302 | 22.1.8 | 1.2.6  |
| i586-unknown-linux-gnu         | 5.4.302 | 22.1.8 | 2.43   |
| i586-unknown-linux-musl        | 5.4.302 | 22.1.8 | 1.2.6  |
| i686-unknown-linux-gnu         | 5.4.302 | 22.1.8 | 2.43   |
| i686-unknown-linux-musl        | 5.4.302 | 22.1.8 | 1.2.6  |
| loongarch64-unknown-linux-gnu  | 5.19.16 | 22.1.8 | 2.43   |
| loongarch64-unknown-linux-musl | 5.19.16 | 22.1.8 | 1.2.6  |
| mips-unknown-linux-gnu         | 5.4.302 | 22.1.8 | 2.43   |
| mips-unknown-linux-gnusf       | 5.4.302 | 22.1.8 | 2.43   |
| mips-unknown-linux-musl        | 5.4.302 | 22.1.8 | 1.2.6  |
| mips-unknown-linux-muslsf      | 5.4.302 | 22.1.8 | 1.2.6  |
| mipsel-unknown-linux-gnu       | 5.4.302 | 22.1.8 | 2.43   |
| mipsel-unknown-linux-gnusf     | 5.4.302 | 22.1.8 | 2.43   |
| mipsel-unknown-linux-musl      | 5.4.302 | 22.1.8 | 1.2.6  |
| mipsel-unknown-linux-muslsf    | 5.4.302 | 22.1.8 | 1.2.6  |
| mips64-unknown-linux-gnu       | 5.4.302 | 22.1.8 | 2.43   |
| mips64-unknown-linux-musl      | 5.4.302 | 22.1.8 | 1.2.6  |
| mips64el-unknown-linux-gnu     | 5.4.302 | 22.1.8 | 2.43   |
| mips64el-unknown-linux-musl    | 5.4.302 | 22.1.8 | 1.2.6  |
| powerpc-unknown-linux-gnu      | 5.4.302 | 22.1.8 | 2.43   |
| powerpc-unknown-linux-musl     | 5.4.302 | 22.1.8 | 1.2.6  |
| powerpcle-unknown-linux-gnu    | 5.4.302 | 22.1.8 | 2.43   |
| powerpcle-unknown-linux-musl   | 5.4.302 | 22.1.8 | 1.2.6  |
| powerpc64-unknown-linux-gnu    | 5.4.302 | 22.1.8 | 2.43   |
| powerpc64-unknown-linux-musl   | 5.4.302 | 22.1.8 | 1.2.6  |
| powerpc64le-unknown-linux-gnu  | 5.4.302 | 22.1.8 | 2.43   |
| powerpc64le-unknown-linux-musl | 5.4.302 | 22.1.8 | 1.2.6  |
| riscv32-unknown-linux-gnu      | 5.4.302 | 22.1.8 | 2.43   |
| riscv32-unknown-linux-musl     | 5.4.302 | 22.1.8 | 1.2.6  |
| riscv64-unknown-linux-gnu      | 5.4.302 | 22.1.8 | 2.43   |
| riscv64-unknown-linux-musl     | 5.4.302 | 22.1.8 | 1.2.6  |
| s390x-ibm-linux-gnu            | 5.4.302 | 22.1.8 | 2.43   |
| s390x-ibm-linux-musl           | 5.4.302 | 22.1.8 | 1.2.6  |
| x86_64-unknown-linux-gnu       | 5.4.302 | 22.1.8 | 2.43   |
| x86_64-unknown-linux-musl      | 5.4.302 | 22.1.8 | 1.2.6  |

## How to use

Download the tarball from the [release page](https://github.com/Matrix3600/clang-cross/releases).
Choose the one that corresponds to the `host` system on which the toolchain will run, and the `target` for which you want to generate executables (from the list above).

The tarball names are `clang-<host>_<target>.tar.xz` for Linux,
or `clang-<host>_<target>.7z` for Windows.

On Linux, extract the tarball to `/opt/x-tools/clang`:
```
sudo mkdir -p /opt/x-tools/clang
sudo tar -xf clang-<host>_<target>.tar.xz -C /opt/x-tools/clang

export PATH="/opt/x-tools/clang/<target>/bin:$PATH"
clang hello.c -o hello
```

On Windows, extract it to `C:\x-tools\clang`:
```
mkdir C:\x-tools\clang
tar -xf clang-<host>_<target>.7z -C C:\x-tools\clang
PATH=C:\x-tools\clang\<target>\bin;%PATH%
clang hello.c -o hello
```

It is not necessary to specify the --sysroot and --target options for clang.

## How to build

Fork this project, activate Github Actions for the repository, and create a new tag for the release:

```
git tag <tag_name>
git push origin <tag_name>
```
This builds the files and creates a draft release.

The host architecture (on which the toolchains run) depends on the beginning of the tag name:
- "x64-" for Linux x86-64
- "arm64-" for Linux ARM64
- "win-x64-" for Windows x86-64
- "win-arm64-" for Windows ARM64
- "macos-x64-" for macOS x64
- "macos-arm64-" for macOS ARM64

Otherwise you can also publish a release directly.

Or build manually for your machine's architecture:
```
./scripts/make <target>
```

## License

MIT

## Acknowledgements

We would like to express our gratitude to the following individuals and projects:

- [cross-tools](https://github.com/cross-tools)
- [llvm-mingw](https://github.com/mstorsjo/llvm-mingw)
- [llvm](https://llvm.org)
- [linux](https://kernel.org)
- [glibc](https://www.gnu.org/software/libc)
- [musl-libc](https://musl.libc.org)
