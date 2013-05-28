This in a Two-Player game developed in Assembly Language, as part of CS2610 course.

This games requires "dosbox" or "dosemu"

Run the following commands in the terminal
1. sudo apt-get install dosbox
2. sudo dosbox

To compile this game, run the following in dosbox:
1. mount C /path/to/directory/MASM
2. C:
3. masm.exe connect4.asm
4. link.exe connect4.obj
5. connect4.exe

They command should be of the form :
p<player Number> <row><col>

rows are numbered from a to f and columns are numbered from 1 to 6; with left bottom (a, 1)
