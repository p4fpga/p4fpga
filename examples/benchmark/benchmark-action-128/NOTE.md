
## How to use this benchmark ?

We can vary how many action operations is performed on a packet with
this benchmark. The knob is at line 229 in ControlGenerated.bsv.  You
can set the number of steps in this Engine to 1 .. 8. For example, use
Engine#(1, xxx), Engine#(2, xxx) ...  for action engine that perform
6, 12, ... operations on incoming packet.
