import sys
import numpy as np
import math

#order=[3, 4, 5, 6, 7, 8, 9, 10]
#for pe in order:
#    width=np.power(2, pe)
#    out = sys.stdout
#    out.write("interface PEnc%s;\n" % width)
#    out.write("   interface Put#(Bit#(%s)) oht;\n" % width)
#    out.write("   interface Get#(Bit#(%s)) bin;\n" % int(math.log(width, 2)))
#    out.write("   interface Get#(Bool) vld;\n")
#    out.write("endinterface\n")
#    out.write("(* synthesize *)\n")
#    out.write("module mkPriorityEncoder(PEnc#(%s));\n" % width)
#    out.write("  FIFO#(Bit#(TLog#(%s))) binpipe <- mkFIFO;\n" % width)
#    out.write("  FIFO#(Bool) vldpipe <- mkFIFO;\n")
#    out.write("  FIFO#(Bit#(%s)) p0_infifo <- mkFIFO;\n" % (width/2))
#    out.write("  FIFO#(Bit#(%s)) p1_infifo <- mkFIFO;\n" % (width/2))
#    out.write("  FIFOF#(Bit#(%s)) oht_fifo <- mkBypassFIFOF;\n" % width)
#    out.write("\n")
#    out.write("  PEnc%s p0 <- mkPriorityEncoder%s();\n" % (width/2, width/2))
#    out.write("  PEnc%s p1 <- mkPriorityEncoder%s();\n" % (width/2, width/2))
#    out.write("\n")
#    out.write("  rule set_input;\n")
#    out.write("     let bin <- toGet(oht_fifo).get;\n")
#    out.write("     p0.oht.put(bin[%s:0]);\n" % (width/2-1))
#    out.write("     p1.oht.put(bin[%s:%s]);\n" % (width-1, width/2))
#    out.write("  endrule\n")
#    out.write("\n")
#    out.write("  rule set_output;\n")
#    out.write("     let valid0 <- p0.vld.get;\n")
#    out.write("     let valid1 <- p1.vld.get;\n")
#    out.write("     let bin0 <- p0.bin.get;\n")
#    out.write("     let bin1 <- p1.bin.get;\n")
#    out.write("     Bit#(TLog#(%s)) output_bin = valid0 ? {1'b0, bin0} : {1'b1, bin1};\n" % width)
#    out.write("     Bool output_vld = boolor(valid0, valid1);\n")
#    out.write("     binpipe.enq(output_bin);\n")
#    out.write("     vldpipe.enq(output_vld);\n")
#    out.write("  endrule\n")
#    out.write("\n")
#    out.write("  interface Put oht;\n")
#    out.write("     method Action put(Bit#(%s) v);\n" % width)
#    out.write("        oht_fifo.enq(v);\n")
#    out.write("     endmethod\n")
#    out.write("  endinterface\n")
#    out.write("  interface bin = fifoToGet(binpipe);\n")
#    out.write("  interface vld = fifoToGet(vldpipe);\n")
#    out.write("endmodule\n")
#    out.write("\n")
#

order=[4, 6, 8, 10]
for pe in order:
    width = np.power(2, pe)
    out = sys.stdout
    out.write("instance PriorityEncoder#(%s);\n" % width);
    out.write("   module mkPriorityEncoder(PEnc#(%s));\n" % width);
    out.write("      Vector#(4, Reg#(Bit#(%s))) binIR <- replicateM(mkReg(0));\n" % (pe - 2));
    out.write("      FIFO#(Bool) vldpipe <- mkFIFO;\n");
    out.write("      FIFO#(Bit#(%s)) binpipe <- mkFIFO;\n" % pe);
    out.write("\n");
    out.write("      Vector#(4, PEnc#(%s)) pe4_cam <- replicateM(mkPriorityEncoder());\n" % (width/4));
    out.write("      PEnc#(4) pe4_cam_out0 <- mkPriorityEncoder();\n");
    out.write("\n");
    out.write("      rule bin_in;\n");
    out.write("         Bool vldI0 <- pe4_cam[0].vld.get;\n");
    out.write("         Bool vldI1 <- pe4_cam[1].vld.get;\n");
    out.write("         Bool vldI2 <- pe4_cam[2].vld.get;\n");
    out.write("         Bool vldI3 <- pe4_cam[3].vld.get;\n");
    out.write("         for (Integer i=0; i<4; i=i+1) begin\n");
    out.write("            Bit#(%s) binI <- pe4_cam[i].bin.get;\n" % (pe - 2));
    out.write("            binIR[i] <= binI;\n");
    out.write("         end\n");
    out.write("         pe4_cam_out0.oht.put({pack(vldI3), pack(vldI2), pack(vldI1), pack(vldI0)});\n");
    out.write("      endrule\n");
    out.write("\n");
    out.write("      rule vld_out;\n");
    out.write("         let v <- pe4_cam_out0.vld.get;\n");
    out.write("         vldpipe.enq(v);\n");
    out.write("      endrule\n");
    out.write("\n");
    out.write("      rule bin_out;\n");
    out.write("         let v <- pe4_cam_out0.bin.get;\n");
    out.write("         binpipe.enq({v, binIR[v]});\n");
    out.write("      endrule\n");
    out.write("\n");
    out.write("      interface Put oht;\n");
    out.write("         method Action put(Bit#(%s) v);\n" % width);
    out.write("            for (Integer i=0; i<4; i=i+1) begin\n");
    out.write("               pe4_cam[i].oht.put(v[%s*(i+1)/4-1:%s*i/4]);\n" % (width, width));
    out.write("            end\n");
    out.write("         endmethod\n");
    out.write("      endinterface\n");
    out.write("      interface bin = fifoToGet(binpipe);\n");
    out.write("      interface vld = fifoToGet(vldpipe);\n");
    out.write("   endmodule\n");
    out.write("endinstance\n");
    out.write("\n");
