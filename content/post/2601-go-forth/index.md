---
title: Go Forth!
date: 2026-01-07
tags:
  - embedded
  - forth
  - arduino
---

I wanted to dip my toes in embedded programming for a while. Big part of it is nostalgia. The 8-bit MCUs are very much like the 8-bit microcomputers that I started on. It's even better with the plethora of I/O options they provide. The overall complexity is manageable, you can really understand everything that's going on in the device down to the hardware bits. And you don't need layers of software to make some LEDs blink or to read some sensors.

Recently I ran across [this post from Eli Bendersky](https://eli.thegreenplace.net/2025/implementing-forth-in-go-and-c/) where he talks about implementing Forth. It piqued my interest because I used Forth long time ago on the first computer I ever had, a Sharp MZ-800.

![](mz-800.jpg)

 As many of the microcomputers of that era it booted into Basic and you loaded other software from cassette tapes (that thing on top right is cassette player/recorder). If you were at all curious you quickly got bored of Basic and started playing with assembler. Somehow I got my hands on an implementation of Forth and I used it to drive this DIY pen-plotter built from a kit based on a Russian kid's constructor set that was popular in my neck of the woods then. It was just a simple metal frame with a roller moving the sheet of paper up and down and a head holding a Sharpie moving along the roller left and right. One step motor driving each of those plus a mechanism that lifted or lowered the pen. All this driven through the a standard parallel port. I don't think there was much in terms of electronics. I can't find any pictures, but the frame style looked something like this:

![](konstruktor.jpg)

I sunk many, many hours into that project and had a blast, but I don't think I understood Forth deep enough to appreciate its beautiful simplicity. It was just an interesting language that I used to implement what I needed (mind you there was no internet and documentation was scarce behind the iron curtain, so I probably didn't have much to go by anyway).

Fast-forward few decades and Eli's article and the fantastic references he points to opened my eyes. The threaded interpretive language technique is brilliant in its sophisticated simplicity. It adds a structured interpreter to plain assembler with minimal overhead, combining both seamlessly. Unsurprisingly many Forths include an assembler for their targets, implemented in Forth of course.

I share Eli's doubts about Forth's suitability for general purpose programming and large complex systems, but it definitely looks like a great fit for simple embedded systems. You can implement a Forth core in [less than 512 bytes](https://compilercrim.es/bootstrap/miniforth/) so it can fit into tiniest 8-bit MCUs with lots of room to spare. Indeed there are a few Forths readily available for 8-bit MCUs; the two that caught my attention are

* https://amforth.sourceforge.net/
* https://flashforth.com/index.html

Both of these demonstrate another really attractive aspect of the language. It's dual interpretation/compilation nature is conventionally baked in, so it naturally provides a REPL style interface to a Forth running on an MCU; usually mediated through whatever serial interface is available. So as soon as you upload Forth into the board you can open up a serial monitor and start interacting with it. You can poke around to see what's going on inside, add new "words" (Forth's functions) on the fly and invoke them immediately. You have a powerful and fully interactive system to do your exploration with. Makes one reminisce about the wonderful "objects at your fingertips" feel of Smalltalk.

Now granted, with a polished platform like Arduino with its powerful libraries a lot of the work is already done for you, you don't really need to know that much to get something done. With Forth you just have the bare metal and basic Forth vocabulary to work with so you need to learn a lot about the MCU to do anything really, but that is the point if your goal is learning.

A notable exception I ran across is ESP32Forth which gives you the interactive nature of Forth along with all the Arduino goodies. This is because it's written in C and linked with all the Arduino libraries. You kind of get the best of both worlds, but also none of it. You get all the Arduino ease and also the Forth interactiveness. But you are now also separated from the metal by whatever the C-compiler does and whatever bloat comes with it. When I tried it compiled to well over a megabyte although I'm guessing most of it is statically linked libraries. All that said I really don't mean to put ESP32Forth down. It is very well executed, I found its code quite readable, I learned a lot from it. And it was actually the easiest one to get going when I tried (more on that later). At this point it would be my first choice if I wanted to start building embedded projects quickly.

One thing that is hard to miss is that nowadays the 32-bit MCUs are plentiful, orders of magnitude more powerful and just as cheap as the 8-bit MCUs; it seems the 8-bits are probably somewhat past their time. However there seem to be fewer open-source Forths targeting the 32-bit platforms. Clearly ESP32Forth is in this camp, supporting Xtensa and RISC-V MCUs. But I ended up going with AmForth, which is originally written for the 8-bit MCUs, but has some experimental bits for ARM and RISC-V as well. It is a bare-metal, plain assembler based system and I like how the project is organized.

So, Forth is what I'm using at least for next little while in my embedded adventures. Currently I'm working on getting AmForth running on Arduino Uno R4 Wifi board, which is based on Renesas ARM Cortex-M4 core (https://github.com/mkobetic/amforth/pull/1). I also have some ESP32-C6 (RISC-V) that I'm really curious, so that will probably be my next pet project. I want to write some more specific articles to capture what I learned, hopefully for not just my own benefit. A lot of information I find is somewhat dated or incomplete, maybe I can fill some gaps to help others along.

P.S.: If you don't care about embedded stuff, [this little gem](https://github.com/remko/waforth) targets WebAssembly.


# References (that caught my attention)

## Implementing Forth
* the one that sent me down the rabbit hole https://eli.thegreenplace.net/2025/implementing-forth-in-go-and-c/
* very good and thorough overview https://www.bradrodriguez.com/papers/moving1.htm
* a shorter but very good overview https://iforth.nl/Forth_Kogge.pdf
* x86 Forth in 512 bytes https://compilercrim.es/bootstrap/miniforth/
* this book is excellent [Threaded Interpretive Languages](https://archive.org/details/R.G.LoeligerThreadedInterpretiveLanguagesTheirDesignAndImplementationByteBooks1981)


## About Forth

* standard reference https://forth-standard.org/
* bit long and winding but with a lot of historical context https://ratfactor.com/forth/the_programming_language_that_writes_itself.html

## Embedded Forth

### Atmel AVR8 MCUs
* https://amforth.sourceforge.net/
* https://flashforth.com/index.html
* flashforth help and examples https://arduino-forth.com/

### ESP32
* https://esp32forth.appspot.com (https://github.com/flagxor/ueforth)
* esp32forth help and examples https://esp32.arduino-forth.com/

### AmForth
* documentation https://amforth.sourceforge.net/
* project https://sourceforge.net/projects/amforth/

### muforth
Cross-compiling Forth that looks very interesting as well, lots to learn there too.
* https://muforth.dev/

### WebAssembly
* https://github.com/remko/waforth



