//
// resize --
//     Size conversion using zero extend or truncate as appropriate. Manipulates high-order bits.
//
function t_DST resize(t_SRC src)
    provisos (Bits#(t_DST, n_DST_BITS),
              Bits#(t_SRC, n_SRC_BITS),
              Max#(n_DST_BITS, n_SRC_BITS, n_BITS));
    
    Bit#(n_BITS) x = zeroExtendNP(pack(src));
    return unpack(truncateNP(x));
endfunction

//
// resizeLSB --
//     Size conversion using zero extend or truncate as appropriate. Manipulates low-order bits.
//
function t_DST resizeLSB(t_SRC src)
    provisos (Bits#(t_DST, n_DST_BITS),
              Bits#(t_SRC, n_SRC_BITS),
              Max#(n_DST_BITS, n_SRC_BITS, n_BITS));
    
    Bit#(n_BITS) x = zeroExtendNP(reverseBits(pack(src)));
    return unpack(reverseBits(truncateNP(x)));
endfunction

//
// sameSizeNP --
//     Assert that src and dst types are the same size.  This is only
//     needed when the compiler fails to prove that a pair of complex
//     types are guaranteed to be the same size.
function t_DST sameSizeNP(t_SRC src)
    provisos (Bits#(t_DST, n_DST_BITS),
              Bits#(t_SRC, n_SRC_BITS));
    
    let sb = valueOf(n_SRC_BITS);
    let db = valueOf(n_DST_BITS);
    let err = error("incorrect sameSizeNP from " + integerToString(sb) + 
                    " to " + integerToString(db) + ".");

    return (sb != db) ? err : unpack(truncateNP(pack(src)));
endfunction


//
// Provided by Bluespec
//

//
// Extend and truncate functions that do not introduce proviso requirements
// for the size relationship between the input and output types.  Eliminating
// the proviso requirment is not free!  Unlike the built in extend and
// truncate functions, errors caused by misuse of these functions will
// generate ambiguous messages that are hard to track back to the source.
//

typeclass ExtendNP#(type a, numeric type m, numeric type n) ;
   function a#(m) extendNP(a#(n) x);
   function a#(m) zeroExtendNP(a#(n) x);
   function a#(m) signExtendNP(a#(n) x);
   function a#(m) truncateNP(a#(n) x);
endtypeclass

instance ExtendNP#(Bit, m, n);
   function Bit#(m) extendNP(Bit#(n) b)     = zeroExtendNPBits(b);
   function Bit#(m) zeroExtendNP(Bit#(n) b) = zeroExtendNPBits(b);
   function Bit#(m) signExtendNP(Bit#(n) b) = signExtendNPBits(b);
   function Bit#(m) truncateNP(Bit#(n) b)   = truncateNPBits(b);
endinstance

instance ExtendNP#(Int, m, n);
   function Int#(m) extendNP(Int#(n) b)     = unpack (signExtendNPBits(pack(b)));
   function Int#(m) zeroExtendNP(Int#(n) b) = unpack (zeroExtendNPBits(pack(b)));
   function Int#(m) signExtendNP(Int#(n) b) = unpack (signExtendNPBits(pack(b)));
   function Int#(m) truncateNP(Int#(n) b)   = unpack (truncateNPBits(pack(b)));
endinstance

instance ExtendNP#(UInt, m, n);
   function UInt#(m) extendNP(UInt#(n) b)     = unpack (zeroExtendNPBits(pack(b)));
   function UInt#(m) zeroExtendNP(UInt#(n) b) = unpack (zeroExtendNPBits(pack(b)));
   function UInt#(m) signExtendNP(UInt#(n) b) = unpack (signExtendNPBits(pack(b)));
   function UInt#(m) truncateNP(UInt#(n) b)   = unpack (truncateNPBits(pack(b)));
endinstance

function Bit#(m) zeroExtendNPBits(Bit#(n) din)
   provisos(Add#(m, n, mn));
   let mi = valueOf(m);
   let ni = valueOf(n);
   let err = error ("incorrect zeroExtendNP from " + integerToString(ni) + 
                    " to " + integerToString(mi) + ".");
   Bit#(mn) x = zeroExtend(din) ;
   return (mi < ni) ? err : truncate(x);
endfunction

function Bit#(m) signExtendNPBits(Bit#(n) din)
   provisos(Add#(m, n, mn));
   let mi = valueOf(m);
   let ni = valueOf(n);
   let err = error ("incorrect signExtendNP from " + integerToString(ni) + 
                    " to " + integerToString(mi) + ".");
   Bit#(mn) x = signExtend(din) ;
   return (mi < ni) ? err : truncate(x);
endfunction

function Bit#(m) truncateNPBits(Bit#(n) din)
   provisos(Add#(m, n, mn));
   let mi = valueOf(m);
   let ni = valueOf(n);
   let err = error ("incorrect truncateNP from " + integerToString(ni) + 
                    " to " + integerToString(mi) + ".");
   Bit#(mn) x = zeroExtend(din) ;
   return (mi > ni) ? err : truncate(x);
endfunction
