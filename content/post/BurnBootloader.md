
Bootloaders are probably not the first thing one would recommend a beginner to dive into, but if you're dead set on running Forth on your board, you'll have to contend with it whether you want to or not. The details discussed below are from Atmel Atmega MCUs (I was using ATmega 2560), but the same concepts likely apply to other MCU families as well.

# What is a bootloader

Bootloader is a bit of code that is pre-loaded into the MCUs flash memory and is the first thing that runs when the MCU starts up. On learning/hobby boards like the Arduinos its  purpose is to allow programming application code into the MCU's flash memory. This allows programming the MCU without external programming hardware. The boards usually have a USB port that is connected to one of MCUs serial interfaces (UART). The bootloader watches the interface for communication using a programming protocol. The bootloader of my ATMega 2560 uses stk500 protocol. If the protocol is not detected by the bootloader it will let the previously programmed application run.

To program the MCU you simply connect the board to a computer with a standard USB cable. When you have the binary code to write to MCU's flash memory, a tool like avrdude that speaks the programming protocol supported by the bootloader can get it there.

# Bootloader vs MCUs programming interface

Initially I misunderstood an important aspect of the whole MCU programming picture. The hobby boards would generally have two MCUs. There would be the main one that the board is for, but there would also be another, smaller one that is hooked up to the USB port.

If you read the MCU datasheet there will be an entire chapter on using the MCU ports and pins to write its flash memory [^1]. So I thought this is what the second MCU was doing when you are programming the board. Kinda like an external MCU programmer that is embedded in the board. This is NOT what is going on when programming these boards. You wouldn't need a bootloader on the main MCU if this is how things worked. The hardware programming interface allows programming the MCU regardless of what state it is in, e.g. when it is blank after a complete flash memory erasure.

The bootloader, being just a bit of code that the MCU executes, uses different way of writing into the flash, usually through the MCU's special registers. This process would be described in a different chapter of the datasheet, probably in the discussion of the special registers used for this purpose.

So what is the second MCU for? Its purpose is to implement the USB protocol and to relay its payload to the main MCU through a plain UART connection between the two MCUs. That's how the programming protocol bits make it to the bootloader running on the main MCU.

Why is this important?



1) Flashed ArduinoISP sketch to UnoR4
2) Hooked up wiring as per the sketch documentation
   (https://docs.arduino.cc/built-in-examples/arduino-isp/ArduinoISP/)
   * connected ICSP pins except RESET
   * connected Uno4 pin 10 to Mega RESET pin
3) Hooked up leds as per sketch info
4) Tools>Board to Mega 2560
5) Tools>Programmer to "Arduino as ISP" (NOT ArduinoISP !!!)
6) Tools>Burn Bootloader (output below)
7) Noticed in the output that the second avrdude command locked the BLS again
8) Reran the commands manually again removing the locking from the second command (-Ulock:w:0x0F:m
)

"/Users/martin/Library/Arduino15/packages/arduino/tools/avrdude/6.3.0-arduino17/bin/avrdude" \
"-C/Users/martin/Library/Arduino15/packages/arduino/tools/avrdude/6.3.0-arduino17/etc/avrdude.conf" \
-v -patmega2560 -cstk500v1 -P/dev/cu.usbmodemB43A45B4700C2 -b19200 \
-e -Ulock:w:0x3F:m -Uefuse:w:0xFD:m -Uhfuse:w:0xD8:m -Ulfuse:w:0xFF:m

avrdude: Version 6.3-20190619
         Copyright (c) 2000-2005 Brian Dean, http://www.bdmicro.com/
         Copyright (c) 2007-2014 Joerg Wunsch

         System wide configuration file is "/Users/martin/Library/Arduino15/packages/arduino/tools/avrdude/6.3.0-arduino17/etc/avrdude.conf"
         User configuration file is "/Users/martin/.avrduderc"
         User configuration file does not exist or is not a regular file, skipping

         Using Port                    : /dev/cu.usbmodemB43A45B4700C2
         Using Programmer              : stk500v1
         Overriding Baud Rate          : 19200
         AVR Part                      : ATmega2560
         Chip Erase delay              : 9000 us
         PAGEL                         : PD7
         BS2                           : PA0
         RESET disposition             : dedicated
         RETRY pulse                   : SCK
         serial program mode           : yes
         parallel program mode         : yes
         Timeout                       : 200
         StabDelay                     : 100
         CmdexeDelay                   : 25
         SyncLoops                     : 32
         ByteDelay                     : 0
         PollIndex                     : 3
         PollValue                     : 0x53
         Memory Detail                 :

                                  Block Poll               Page                       Polled
           Memory Type Mode Delay Size  Indx Paged  Size   Size #Pages MinW  MaxW   ReadBack
           ----------- ---- ----- ----- ---- ------ ------ ---- ------ ----- ----- ---------
           eeprom        65    10     8    0 no       4096    8      0  9000  9000 0x00 0x00
           flash         65    10   256    0 yes    262144  256   1024  4500  4500 0x00 0x00
           lfuse          0     0     0    0 no          1    0      0  9000  9000 0x00 0x00
           hfuse          0     0     0    0 no          1    0      0  9000  9000 0x00 0x00
           efuse          0     0     0    0 no          1    0      0  9000  9000 0x00 0x00
           lock           0     0     0    0 no          1    0      0  9000  9000 0x00 0x00
           calibration    0     0     0    0 no          1    0      0     0     0 0x00 0x00
           signature      0     0     0    0 no          3    0      0     0     0 0x00 0x00

         Programmer Type : STK500
         Description     : Atmel STK500 Version 1.x firmware
         Hardware Version: 2
         Firmware Version: 1.18
         Topcard         : Unknown
         Vtarget         : 0.0 V
         Varef           : 0.0 V
         Oscillator      : Off
         SCK period      : 0.1 us

avrdude: AVR device initialized and ready to accept instructions

Reading | ################################################## | 100% 0.02s

avrdude: Device signature = 0x1e9801 (probably m2560)
avrdude: erasing chip
avrdude: reading input file "0x3F"
avrdude: writing lock (1 bytes):

Writing | ################################################## | 100% 0.01s

avrdude: 1 bytes of lock written
avrdude: verifying lock memory against 0x3F:
avrdude: load data lock data from input file 0x3F:
avrdude: input file 0x3F contains 1 bytes
avrdude: reading on-chip lock data:

Reading | ################################################## | 100% 0.01s

avrdude: verifying ...
avrdude: 1 bytes of lock verified
avrdude: reading input file "0xFD"
avrdude: writing efuse (1 bytes):

Writing | ################################################## | 100% 0.01s

avrdude: 1 bytes of efuse written
avrdude: verifying efuse memory against 0xFD:
avrdude: load data efuse data from input file 0xFD:
avrdude: input file 0xFD contains 1 bytes
avrdude: reading on-chip efuse data:

Reading | ################################################## | 100% 0.01s

avrdude: verifying ...
avrdude: 1 bytes of efuse verified
avrdude: reading input file "0xD8"
avrdude: writing hfuse (1 bytes):

Writing | ################################################## | 100% 0.01s

avrdude: 1 bytes of hfuse written
avrdude: verifying hfuse memory against 0xD8:
avrdude: load data hfuse data from input file 0xD8:
avrdude: input file 0xD8 contains 1 bytes
avrdude: reading on-chip hfuse data:

Reading | ################################################## | 100% 0.01s

avrdude: verifying ...
avrdude: 1 bytes of hfuse verified
avrdude: reading input file "0xFF"
avrdude: writing lfuse (1 bytes):

Writing | ################################################## | 100% 0.01s

avrdude: 1 bytes of lfuse written
avrdude: verifying lfuse memory against 0xFF:
avrdude: load data lfuse data from input file 0xFF:
avrdude: input file 0xFF contains 1 bytes
avrdude: reading on-chip lfuse data:

Reading | ################################################## | 100% 0.01s

avrdude: verifying ...
avrdude: 1 bytes of lfuse verified

avrdude done.  Thank you.

"/Users/martin/Library/Arduino15/packages/arduino/tools/avrdude/6.3.0-arduino17/bin/avrdude" \
"-C/Users/martin/Library/Arduino15/packages/arduino/tools/avrdude/6.3.0-arduino17/etc/avrdude.conf" \
-v -patmega2560 -cstk500v1 -P/dev/cu.usbmodemB43A45B4700C2 -b19200 \
"-Uflash:w:/Users/martin/Library/Arduino15/packages/arduino/hardware/avr/1.8.6/bootloaders/stk500v2/stk500boot_v2_mega2560.hex:i" 
-Ulock:w:0x0F:m

avrdude: Version 6.3-20190619
         Copyright (c) 2000-2005 Brian Dean, http://www.bdmicro.com/
         Copyright (c) 2007-2014 Joerg Wunsch

         System wide configuration file is "/Users/martin/Library/Arduino15/packages/arduino/tools/avrdude/6.3.0-arduino17/etc/avrdude.conf"
         User configuration file is "/Users/martin/.avrduderc"
         User configuration file does not exist or is not a regular file, skipping

         Using Port                    : /dev/cu.usbmodemB43A45B4700C2
         Using Programmer              : stk500v1
         Overriding Baud Rate          : 19200
         AVR Part                      : ATmega2560
         Chip Erase delay              : 9000 us
         PAGEL                         : PD7
         BS2                           : PA0
         RESET disposition             : dedicated
         RETRY pulse                   : SCK
         serial program mode           : yes
         parallel program mode         : yes
         Timeout                       : 200
         StabDelay                     : 100
         CmdexeDelay                   : 25
         SyncLoops                     : 32
         ByteDelay                     : 0
         PollIndex                     : 3
         PollValue                     : 0x53
         Memory Detail                 :

                                  Block Poll               Page                       Polled
           Memory Type Mode Delay Size  Indx Paged  Size   Size #Pages MinW  MaxW   ReadBack
           ----------- ---- ----- ----- ---- ------ ------ ---- ------ ----- ----- ---------
           eeprom        65    10     8    0 no       4096    8      0  9000  9000 0x00 0x00
           flash         65    10   256    0 yes    262144  256   1024  4500  4500 0x00 0x00
           lfuse          0     0     0    0 no          1    0      0  9000  9000 0x00 0x00
           hfuse          0     0     0    0 no          1    0      0  9000  9000 0x00 0x00
           efuse          0     0     0    0 no          1    0      0  9000  9000 0x00 0x00
           lock           0     0     0    0 no          1    0      0  9000  9000 0x00 0x00
           calibration    0     0     0    0 no          1    0      0     0     0 0x00 0x00
           signature      0     0     0    0 no          3    0      0     0     0 0x00 0x00

         Programmer Type : STK500
         Description     : Atmel STK500 Version 1.x firmware
         Hardware Version: 2
         Firmware Version: 1.18
         Topcard         : Unknown
         Vtarget         : 0.0 V
         Varef           : 0.0 V
         Oscillator      : Off
         SCK period      : 0.1 us

avrdude: AVR device initialized and ready to accept instructions

Reading | ################################################## | 100% 0.02s

avrdude: Device signature = 0x1e9801 (probably m2560)
avrdude: NOTE: "flash" memory has been specified, an erase cycle will be performed
         To disable this feature, specify the -D option.
avrdude: erasing chip
avrdude: reading input file "/Users/martin/Library/Arduino15/packages/arduino/hardware/avr/1.8.6/bootloaders/stk500v2/stk500boot_v2_mega2560.hex"
avrdude: writing flash (261406 bytes):

Writing | ################################################## | 100% 0.00s

avrdude: 261406 bytes of flash written
avrdude: verifying flash memory against /Users/martin/Library/Arduino15/packages/arduino/hardware/avr/1.8.6/bootloaders/stk500v2/stk500boot_v2_mega2560.hex:
avrdude: load data flash data from input file /Users/martin/Library/Arduino15/packages/arduino/hardware/avr/1.8.6/bootloaders/stk500v2/stk500boot_v2_mega2560.hex:
avrdude: input file /Users/martin/Library/Arduino15/packages/arduino/hardware/avr/1.8.6/bootloaders/stk500v2/stk500boot_v2_mega2560.hex contains 261406 bytes
avrdude: reading on-chip flash data:

Reading | ################################################## | 100% 0.00s

avrdude: verifying ...
avrdude: 261406 bytes of flash verified
avrdude: reading input file "0x0F"
avrdude: writing lock (1 bytes):

Writing | ################################################## | 100% 0.02s

avrdude: 1 bytes of lock written
avrdude: verifying lock memory against 0x0F:
avrdude: load data lock data from input file 0x0F:
avrdude: input file 0x0F contains 1 bytes
avrdude: reading on-chip lock data:

Reading | ################################################## | 100% 0.01s

avrdude: verifying ...
avrdude: 1 bytes of lock verified

avrdude done.  Thank you.


### References

* https://www.gammon.com.au/bootloader
* https://github.com/arduino/ArduinoCore-avr/blob/master/bootloaders/stk500v2

[^1]: Chapter 29. Memory Programming in the [ATmega datasheet](https://ww1.microchip.com/downloads/en/devicedoc/atmel-2549-8-bit-avr-microcontroller-atmega640-1280-1281-2560-2561_datasheet.pdf)

[^2]: Chapter 28. Boot Loader Support in the [ATmega datasheet](https://ww1.microchip.com/downloads/en/devicedoc/atmel-2549-8-bit-avr-microcontroller-atmega640-1280-1281-2560-2561_datasheet.pdf)