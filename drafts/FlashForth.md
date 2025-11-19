


# https://flashforth.com/index.html
* https://arduino-forth.com/ ()

# MPLAB X IDE
* recompiled the ihex image, note that the ihex addresses are byte addresses not work addresses!
* flashing it failed trying to write to bootloader section which is locked
* can we fit it in side by side with the arduino bootloader?
* why are the memory sizes in the IDE wrong after selecting the right chip ATmega2560
* to produce an anotated listing file add compiler options:
    `-Wa,-adhlns=${DISTDIR}/output.lst`

    -Wa,: This prefix tells GCC to pass the following options directly to the assembler.
    -adhlns="output.lst": These are options for the assembler (as):
      -a: Generates an assembly listing.
      -d: Includes debugging information in the listing.
      -h: Includes high-level source code (if debug info is available).
      -l: Includes line numbers.
      -n: Omits forms processing.
      -s: Includes symbol table.
      ="output.lst": Specifies the name of the output listing file.

* had to modify ~/Users/martin~/.mchp_packs/Microchip/ATmega_DFP/3.4.282/xc8/avr/include/avr/iom2560.h to move the `#pragma GCC poison ...` to the end, otherwise everything that followed (like definition of RAMEND, FLASHEND, etc) was missing from the final output.

# Burning

* had to reset lock bits => erase chip, flash bootloader again
* it seemed there's room for both the FF NRWW part and the bootloader (they didn't seem to overlap) so tried to burn both, but the bootloader wouldn't give up control to FF
* only burning FF by itself without bootloader got it to work (why?)


# AMForth

https://amforth.sourceforge.net/index.html


# Burning the Boot Loader section
* Using Arduino as programmer https://docs.arduino.cc/built-in-examples/arduino-isp/ArduinoISP/
* Flashing the second core like 16U2 https://github.com/NicoHood/HoodLoader2/wiki
* Arduino bootloaders https://github.com/arduino/ArduinoCore-avr/tree/master/bootloaders

# Other

 https://www.instructables.com/Arduino-ICSP-Programming-Cable/
 https://www.gammon.com.au/bootloader