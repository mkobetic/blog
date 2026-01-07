* see how Arduino IDE programs the board => bossac
* see how Arduino IDE debugs the board => openocd config scripts
* unor4 bootloader
    * implements only bare minimum of SAM-BA
    * clamps flash writing to 0x40000
* cloned appl/launchpad-arm
* memmap
* delay.s
* led.s
* debugging & GDB customizations

## ARM Assembler programming

* Whirliwind tour of ARM Assembly https://www.coranac.com/tonc/text/asm.htm

# Arduino UNO R4 Wifi

https://store.arduino.cc/products/uno-r4-wifi

## ARM7M - Cortex M4

https://github.com/arduino/ArduinoCore-renesas/tree/main/libraries/Arduino_FreeRTOS

Whirlwind tour of ARM assembly https://www.coranac.com/tonc/text/asm.htm
Intro to ARM assembly https://azeria-labs.com/writing-arm-assembly-part-1/

## ESP32 wifi chip

https://documentation.espressif.com/esp-at/en/latest/esp32/index.html

# Tutorial

https://docs.freenove.com/projects/fnk0094/en/latest/
(https://github.com/Freenove/Freenove_Super_Starter_Kit_for_Control_Board_V5)

https://forum.digikey.com/t/theory-behind-the-arduino-uno-r4-wifi-12-x-8-led-display-matrix/43827

### Tools

* GNU Assembler https://sourceware.org/binutils/docs/as
* linker scripting https://mcyoung.xyz/2021/06/01/linker-script/
* linker intro https://medium.com/@pc0is0me/an-introduction-to-linker-file-59ce2e9c5e73
* GDB https://sourceware.org/gdb
* GDB server for on-chip-debugger, OpenOCD https://openocd.org/doc/html/index.html