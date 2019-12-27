# mini DYCP

Entry for the CSDb ICC 2019 (4KB) (https://csdb.dk/event/?id=2889), release as "4KB VSP + DYCP/Focus" (https://csdb.dk/release/?id=185398P).

I had slightly wilder plans for this, for example having a sprites-based frame around the 24-char wide DYCP etc, moving that around a bit with VSP. but 4KB fills up pretty quick.

## Building

You'll need GNU make and 64tass (svn) and exomizer. Also gawk if you want to alter the Makefile piping 64tass output to display the number of bytes free between each slab of this horrible example of spaghetti code.
```
$ git clone https://github.com/compyx/mini-dycp.git
$ make
```

## Release

Do a `$ make packed` to generate an exomized binary.
