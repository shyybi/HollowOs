# Installing process

Before everything, thank you for the interest in contributing to HollowOs! 

## How to install 

1. **Clone the repository**
```
git clone https://github.com/shyybi/HollowOs.git
```

2. **Install dependencies**
You will need the following tools:
- `nasm` (assembler)
- `qemu-system-i386` (emulator)
- `i386-elf-gcc` (cross-compiler, optional for kernel builds)

On Ubuntu/Debian:
```
sudo apt update
sudo apt install nasm qemu-system-i386 gcc-i386
```
For cross-compiling:
```
sudo apt install gcc-i386
```
Or, for a proper cross-compiler:
```
sudo apt install gcc-multilib
```
On Arch Linux:
```
sudo pacman -S nasm qemu gcc
```
You may need to build or install a cross-compiler separately for full kernel support.

3. **Build the project**
```
bash ./build.sh build
```
4. **Run the project**
```
bash ./build.sh run
```
5. **Delete build files**
```
bash ./build.sh clean
```

----

Thank you for helping make HollowOs better!