package SynthBuilder;

// A means to allow for easy substitution of polymorphic and synthesizable module

typeclass SynthBuilder #(type ifc);
   module mkSynth # (function module#(ifc) mkMod ()) (ifc);
   module mkSynthStrict # (String msg) (ifc);
endtypeclass

instance SynthBuilder #(ifc);
   module mkSynth #(function module#(ifc) mkMod ()) (ifc);
       messageM ("No concrete definition for type " +
                       (printType (typeOf (mkMod))));

      (*hide*)
      ifc _i <- mkMod;
      return _i;
   endmodule
   module mkSynthStrict #(String usrmsg) (ifc);
      ifc msg = ?;
      ifc msg2 = error ("No concrete definition for type " + usrmsg + " " +
                        (printType (typeOf (msg))));
      return msg2;
   endmodule
endinstance


typeclass SynthBuilder1 #(type ifc, type para);
   module mkSynth1 # (function module#(ifc) mkMod (para px), para p) (ifc);
   module mkSynthStrict1 # (String msg, para p) (ifc);
endtypeclass

instance SynthBuilder1 #(ifc, para);
   module mkSynth1 #(function module#(ifc) mkMod (para px), para p) (ifc);
       messageM ("No concrete definition for type " +
                       (printType (typeOf (mkMod))) +
                 " with parameter " + printType (typeOf (p)));

      (*hide*)
      ifc _i <- mkMod(p);
      return _i;
   endmodule

   module mkSynthStrict1 #(String usrmsg, para p) (ifc);
      ifc msg = ?;
      ifc msg2 = error ("No concrete definition for type " + usrmsg + " " +
                        (printType (typeOf (msg))) +
                        " with parameter " + printType (typeOf (p)));
      return msg2;
   endmodule
endinstance


typeclass SynthBuilder2 #(type ifc, type para0, type para1);
   module mkSynth2 # (function module#(ifc) mkMod (para0 px0, para1 px1),
      para0 p0, para1 p1) (ifc);
   module mkSynthStrict2 # (String msg, para0 p0, para1 p1) (ifc);
endtypeclass

instance SynthBuilder2 #(ifc, para0, para1);
   module mkSynth2 #(function module#(ifc) mkMod (para0 px0, para1 px1),
      para0 p0, para1 p1) (ifc);
       messageM ("No concrete definition for type " +
                       (printType (typeOf (mkMod))) +
                 " with parameters " +
                 printType (typeOf (p0)) + " , " +
                 printType (typeOf (p1))
          );
      (*hide*)
      ifc _i <- mkMod(p0, p1);
      return _i;
   endmodule

   module mkSynthStrict2 #(String usrmsg, para0 p0, para1 p1) (ifc);
      ifc msg = ?;
      ifc msg2 = error ("No concrete definition for type " + usrmsg + " " +
                        " with parameters " +
                        printType (typeOf (p0)) + " , " +
                        printType (typeOf (p1))
                        );
      return msg2;
   endmodule
endinstance


typeclass SynthBuilder3 #(type ifc, type para0, type para1, type para2);
   module mkSynth3 # (function module#(ifc) mkMod (para0 px0, para1 px1, para2 px2),
      para0 p0, para1 p1, para2 p2) (ifc);
   module mkSynthStrict3 # (String msg, para0 p0, para1 p1, para2 p2) (ifc);
endtypeclass

instance SynthBuilder3 #(ifc, para0, para1, para2);
   module mkSynth3 #(function module#(ifc) mkMod (para0 px0, para1 px1, para2 px2),
      para0 p0, para1 p1, para2 p2) (ifc);
       messageM ("No concrete definition for type " +
                       (printType (typeOf (mkMod))) +
                 " with parameters " +
                 printType (typeOf (p0)) + " , " +
                 printType (typeOf (p1)) + " , " +
                 printType (typeOf (p2))
          );
      (*hide*)
      ifc _i <- mkMod(p0, p1, p2);
      return _i;
   endmodule

   module mkSynthStrict3 #(String usrmsg, para0 p0, para1 p1, para2 p2) (ifc);
      ifc msg = ?;
      ifc msg2 = error ("No concrete definition for type " + usrmsg + " " +
                        " with parameters " +
                        printType (typeOf (p0)) + " , " +
                        printType (typeOf (p1)) + " , " +
                        printType (typeOf (p2))
                        );
      return msg2;
   endmodule
endinstance


typeclass SynthBuilder4 #(type ifc, type para0, type para1, type para2, type para3);
   module mkSynth4 # (function module#(ifc) mkMod (para0 px0, para1 px1, para2 px2, para3 px3),
      para0 p0, para1 p1, para2 p2, para3 p3) (ifc);
   module mkSynthStrict4 # (String msg, para0 p0, para1 p1, para2 p2, para3 p3) (ifc);
endtypeclass

instance SynthBuilder4 #(ifc, para0, para1, para2, para3);
   module mkSynth4 #(function module#(ifc) mkMod (para0 px0, para1 px1, para2 px2, para3 px3),
      para0 p0, para1 p1, para2 p2, para3 p3) (ifc);
       messageM ("No concrete definition for type " +
                       (printType (typeOf (mkMod))) +
                 " with parameters " +
                 printType (typeOf (p0)) + " , " +
                 printType (typeOf (p1)) + " , " +
                 printType (typeOf (p2)) + " , " +
                 printType (typeOf (p3))
          );
      (*hide*)
      ifc _i <- mkMod(p0, p1, p2, p3);
      return _i;
   endmodule

   module mkSynthStrict4 #(String usrmsg, para0 p0, para1 p1, para2 p2, para3 p3) (ifc);
      ifc msg = ?;
      ifc msg2 = error ("No concrete definition for type " + usrmsg + " " +
                        " with parameters " +
                        printType (typeOf (p0)) + " , " +
                        printType (typeOf (p1)) + " , " +
                        printType (typeOf (p2)) + " , " +
                        printType (typeOf (p3))
                        );
      return msg2;
   endmodule
endinstance


typeclass SynthBuilder6 #(type ifc, type para0, type para1, type para2, type para3, type para4, type para5);
   module mkSynth6 # (function module#(ifc) mkMod (para0 px0, para1 px1, para2 px2, para3 px3, para4 px4, para5 px5),
      para0 p0, para1 p1, para2 p2, para3 p3, para4 p4, para5 p5) (ifc);
   module mkSynthStrict6 # (String msg, para0 p0, para1 p1, para2 p2, para3 p3, para4 p4, para5 p5) (ifc);
endtypeclass

instance SynthBuilder6 #(ifc, para0, para1, para2, para3, para4, para5);
   module mkSynth6 #(function module#(ifc) mkMod (para0 px0, para1 px1, para2 px2, para3 px3, para4 px4, para5 px5),
      para0 p0, para1 p1, para2 p2, para3 p3, para4 p4, para5 p5) (ifc);
       messageM ("No concrete definition for type " +
                       (printType (typeOf (mkMod))) +
                 " with parameters " +
                 printType (typeOf (p0)) + " , " +
                 printType (typeOf (p1)) + " , " +
                 printType (typeOf (p2)) + " , " +
                 printType (typeOf (p3)) + " , " +
                 printType (typeOf (p4)) + " , " +
                 printType (typeOf (p5))
          );
      (*hide*)
      ifc _i <- mkMod(p0, p1, p2, p3, p4, p5);
      return _i;
   endmodule

   module mkSynthStrict6 #(String usrmsg, para0 p0, para1 p1, para2 p2, para3 p3, para4 p4, para5 p5) (ifc);
      ifc msg = ?;
      ifc msg2 = error ("No concrete definition for type " + usrmsg + " " +
                        " with parameters " +
                        printType (typeOf (p0)) + " , " +
                        printType (typeOf (p1)) + " , " +
                        printType (typeOf (p2)) + " , " +
                        printType (typeOf (p3)) + " , " +
                        printType (typeOf (p4)) + " , " +
                        printType (typeOf (p5))
                        );
      return msg2;
   endmodule
endinstance

////////////////////////////////////////////////////////////////////////////////
/*  To build a specific instance of a module, use the SynthBuildModule as such

`SynthBuildModule( mkHashFilterP,  Filter#(4,16), mkHashFilter_4_16)


Where the first arg is the polymorphic module constructor,
 The second is the provided interface of the module and the last is a unique
 module name for the synthesis.

For a polymorphic module with a single parameter, e.g.
  mkFooP#(parameter ParamType p)(IfcType)
use
`SynthBuildModule1(mkFooP, ConcreteParamType, ConcreteIfcType, mkFooConcrete)

For modules with 2, 3, or 4 parameters, use these macro variants:
`SynthBuildModule2(mkFooP, ParamType0, ParamType1, ConcreteIfcType, mkFooConcrete)
`SynthBuildModule3(mkFooP, ParamType0, ParamType1, ParamType2, ConcreteIfcType, mkFooConcrete)
`SynthBuildModule4(mkFooP, ParamType0, ParamType1, ParamType2, ParamType3, ConcreteIfcType, mkFooConcrete)

 *//////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////
/*  To instantiate an module, use the mkSynth constuctor from the typeclass.

Filter#(pt, ep)  dut <- mkSynth (mkHashFilterP);

 If a matching synthesized version is available it is used, otherwise the default instance is used,
   and a elaboration time message is generated that the default has been used.

Alternatively, use mkSynthStrict, e.g.

 Filter#(pt, ep)  dut <- mkSynthStrict ("mkHashFilterP");

to make sure that a synthesized version exists and generate an error otherwise.
Note the quotes around the name of the polymorphic module.

Variants of mkSynth and mkSynthStrict exist for modules with 1 to 4 parameters,
e.g.

IfcType foo <- mkSynth1(mkFooP, param0);
IfcType foo <- mkSynthStrict1("mkFooP", param0);

IfcType foo <- mkSynth2(mkFooP, param0. param1);
IfcType foo <- mkSynthStrict2("mkFooP", param0, param1);

*///////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/* Note that warning abount orphan instances may be generated.

 Warning: "SynthBuilder.defines", line 11, column 10: (T0127)
  Exporting orphan typeclass instance  Exporting orphan typeclass instance

 These can be safely ignored.
 *//////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////
/*
Here is simple example to show you the utility.

// Consider a polymorphic module
module mkTopP ( Ifc#(a, b) )
// with poly sub modules aa an bb
   SubIfcA#(a)  aa <- mkAP();
   SubIfcB#(b)  bb <- mkBP();
endmodule


If you want synthesizable instance of mkTopP #(4, 16) containing synthesizable
instances aa andd bb,  You would have to create new mkTop_4_16 which is not
polymorphic  and instantiate a non-poly synthesized  mkA_4 and mkB_16.
This is copy and corrupt coding.

Using the SynthBuilder package. This would look like.

module mkTopP ( Ifc#(a, b) )
// with poly sub modules aa an bb
   SubIfcA#(a)  aa <- mkSynth (mkAP());
   SubIfcB#(b) bb <- mkSynth (mkBP());
endmodule

`SynthBuildModule (mkTopP, Ifc#(4,16),  mkTop_4_16)
`SynthBuildModule (mkAP,   SubIfcA#(4), mkA_4)
`SynthBuildModule (mkBP,   SubIfc#(16), mkB_16)

 *//////////////////////////////////////////////////////////////////////////////


endpackage
