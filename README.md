# clang-cross

This is a simple and lightweight project for making a cross-compilation
toolchain with the Clang compiler, and the gnu or musl C library.

These ready-to-use toolchains run on:

- Linux x86_64
- Linux ARM64


## Supported targets

| Target                         | Kernel  | Clang  | Libc   |
|--------------------------------|---------|--------|--------|
| aarch64-unknown-linux-gnu      | 5.4.302 | 22.1.6 | 2.43   |
| aarch64-unknown-linux-musl     | 5.4.302 | 22.1.6 | 1.2.6  |
| arm-unknown-linux-gnueabi      | 5.4.302 | 22.1.6 | 2.43   |
| arm-unknown-linux-gnueabihf    | 5.4.302 | 22.1.6 | 2.43   |
| arm-unknown-linux-musleabi     | 5.4.302 | 22.1.6 | 1.2.6  |
| arm-unknown-linux-musleabihf   | 5.4.302 | 22.1.6 | 1.2.6  |
| armv7-unknown-linux-gnueabi    | 5.4.302 | 22.1.6 | 2.43   |
| armv7-unknown-linux-gnueabihf  | 5.4.302 | 22.1.6 | 2.43   |
| armv7-unknown-linux-musleabi   | 5.4.302 | 22.1.6 | 1.2.6  |
| armv7-unknown-linux-musleabihf | 5.4.302 | 22.1.6 | 1.2.6  |
| i586-unknown-linux-gnu         | 5.4.302 | 22.1.6 | 2.43   |
| i586-unknown-linux-musl        | 5.4.302 | 22.1.6 | 1.2.6  |
| i686-unknown-linux-gnu         | 5.4.302 | 22.1.6 | 2.43   |
| i686-unknown-linux-musl        | 5.4.302 | 22.1.6 | 1.2.6  |
| loongarch64-unknown-linux-gnu  | 5.19.16 | 22.1.6 | 2.43   |
| loongarch64-unknown-linux-musl | 5.19.16 | 22.1.6 | 1.2.6  |
| mips-unknown-linux-gnu         | 5.4.302 | 22.1.6 | 2.43   |
| mips-unknown-linux-gnusf       | 5.4.302 | 22.1.6 | 2.43   |
| mips-unknown-linux-musl        | 5.4.302 | 22.1.6 | 1.2.6  |
| mips-unknown-linux-muslsf      | 5.4.302 | 22.1.6 | 1.2.6  |
| mipsel-unknown-linux-gnu       | 5.4.302 | 22.1.6 | 2.43   |
| mipsel-unknown-linux-gnusf     | 5.4.302 | 22.1.6 | 2.43   |
| mipsel-unknown-linux-musl      | 5.4.302 | 22.1.6 | 1.2.6  |
| mipsel-unknown-linux-muslsf    | 5.4.302 | 22.1.6 | 1.2.6  |
| mips64-unknown-linux-gnu       | 5.4.302 | 22.1.6 | 2.43   |
| mips64-unknown-linux-musl      | 5.4.302 | 22.1.6 | 1.2.6  |
| mips64el-unknown-linux-gnu     | 5.4.302 | 22.1.6 | 2.43   |
| mips64el-unknown-linux-musl    | 5.4.302 | 22.1.6 | 1.2.6  |
| powerpc-unknown-linux-gnu      | 5.4.302 | 22.1.6 | 2.43   |
| powerpc-unknown-linux-musl     | 5.4.302 | 22.1.6 | 1.2.6  |
| powerpcle-unknown-linux-gnu    | 5.4.302 | 22.1.6 | 2.43   |
| powerpcle-unknown-linux-musl   | 5.4.302 | 22.1.6 | 1.2.6  |
| powerpc64-unknown-linux-gnu    | 5.4.302 | 22.1.6 | 2.43   |
| powerpc64-unknown-linux-musl   | 5.4.302 | 22.1.6 | 1.2.6  |
| powerpc64le-unknown-linux-gnu  | 5.4.302 | 22.1.6 | 2.43   |
| powerpc64le-unknown-linux-musl | 5.4.302 | 22.1.6 | 1.2.6  |
| riscv32-unknown-linux-gnu      | 5.4.302 | 22.1.6 | 2.43   |
| riscv32-unknown-linux-musl     | 5.4.302 | 22.1.6 | 1.2.6  |
| riscv64-unknown-linux-gnu      | 5.4.302 | 22.1.6 | 2.43   |
| riscv64-unknown-linux-musl     | 5.4.302 | 22.1.6 | 1.2.6  |
| s390x-ibm-linux-gnu            | 5.4.302 | 22.1.6 | 2.43   |
| s390x-ibm-linux-musl           | 5.4.302 | 22.1.6 | 1.2.6  |
| x86_64-unknown-linux-gnu       | 5.4.302 | 22.1.6 | 2.43   |
| x86_64-unknown-linux-musl      | 5.4.302 | 22.1.6 | 1.2.6  |

## How to use

Download the tarball from the [release page](https://github.com/Matrix3600/clang-cross/releases) and extract it to `/opt/x-tools/clang`:

```sh
sudo mkdir -p /opt/x-tools/clang
sudo tar -xf ${target}.tar.xz -C /opt/x-tools/clang

export PATH="/opt/x-tools/clang/${target}/bin:$PATH"
clang hello.c -o hello
```
Replace `${target}` with one of the targets above.  
It is not necessary to specify the --sysroot and --target options for clang.

## How to build

Fork this project, activate Github Actions for the repository, and create a new tag for the release:

```
git tag <tag_name>
git push origin <tag_name>
```
This builds the files and creates a draft release.

Otherwise you can also publish a release directly.

Or build manually:
```sh
./scripts/make ${target}
```

## License

MIT

## Acknowledgements

We would like to express our gratitude to the following individuals and projects:

- [cross-tools](https://github.com/cross-tools)
- [llvm](https://llvm.org)
- [linux](https://kernel.org)
- [glibc](https://www.gnu.org/software/libc)
- [musl](https://www.musl-libc.org)
