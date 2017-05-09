# R-Type Game

This repository contains the code of a project that was done for an introductory course in Computer Architecture.

## What's it for?

The game was meant as a teaching tool and it explores how computers operate at the processor level. The programmer (student) needs to figure out how to use basic Assembly operations to achieve a game operation closely resembling the "real" game.

## The Processor its assembler and specific assembly

I've put most of the files in with the repository, although they can be found online (links below). The processor, named P3, was built by teachers at my school [Instituto Superior Técnico](https://tecnico.ulisboa.pt) with a pedagogic purpose. There were some boards made for students to test their programs and later on a Java application that simulated the workings of the processor (although with a few nuances that are not relevant here, because of the inaccessibility of the hardware).

Below you can find all the pieces you may need, if you are interested, to program for this processor. Also, the Java simulator is something you will need to try my game.

* `assembler/p3as-mac.exe` - [P3 Assembler for Mac](http://algos.inesc-id.pt/arq-comp/userfiles/downloads/p3as-mac.zip)
* `assembler/p3as-linux.exe` - [P3 Assembler for Linux](http://algos.inesc-id.pt/arq-comp/userfiles/downloads/p3as-linux.zip)
* `assembler/p3as-win.exe` - [P3 Assembler for Windows](http://algos.inesc-id.pt/arq-comp/userfiles/downloads/p3as-mac.zip)
* `p3-sim.jar` - [Java Simulator](http://algos.inesc-id.pt/arq-comp/userfiles/downloads/p3sim.jar)
* `P3 Manual.pdf` - [P3 Manual (Portuguese)](http://algos.inesc-id.pt/~jcm/arq-comp/?download=manual.pdf)

## How does it work?

Glad you ask, thank you for coming this far ;)

There are three steps, you can skip the first if you want to play my version of the game.

1. Assemble the code in `r-type.as`. (You don't need to, there is an assembled file in the repository `r-type.exe`. Skip this step to play.)

```
./assembler/p3as-mac.exe r-type.as
```

This will output two files one with the assembled code `r-type.exe` another with a list of memory references relating to the code `r-type.lis`.

2. Execute the simulator (you need Java for this), just double click/open the `p3-sim.jar` file.

[PROVIDE A PICTURE]

3. Load the file `r-type.exe` into the simulator.
4. Run the simulator.
