
module AsymmetricBRAM_Xilinx(
	CLK,
	RADDR,
	RDATA,
	REN,
	WADDR,
	WDATA,
	WEN
);
parameter	PIPELINED   = 'd 0;
parameter	FORWARDING  = 'd 0;
parameter	WADDR_WIDTH = 'd 0;
parameter	WDATA_WIDTH = 'd 0;
parameter	RADDR_WIDTH = 'd 0;
parameter	RDATA_WIDTH = 'd 0;
parameter	MEMSIZE     = 'd 1;
parameter	REGISTERED  = (PIPELINED  == 0) ? "UNREGISTERED":"CLOCK0";
input   CLK;
input	[RADDR_WIDTH-1:0]   RADDR;
output	[RDATA_WIDTH-1:0]   RDATA;
input	REN;
input	[WADDR_WIDTH-1:0]   WADDR;
input	[WDATA_WIDTH-1:0]   WDATA;
input   WEN;

`define max(a,b) {(a) > (b) ? (a) : (b)}
`define min(a,b) {(a) < (b) ? (a) : (b)}

function integer log2;
input integer value;
reg [31:0] shifted;
integer res;
begin
	if (value < 2)
		log2 = value;
	else
	begin
		shifted = value-1;
		for (res=0; shifted>0; res=res+1)
			shifted = shifted>>1;
		log2 = res;
	end
end
endfunction

localparam maxWIDTH = `max(WDATA_WIDTH, RDATA_WIDTH);
localparam minWIDTH = `min(WDATA_WIDTH, RDATA_WIDTH);

localparam RATIO = maxWIDTH / minWIDTH;
localparam log2RATIO = log2(RATIO);

reg [minWIDTH-1:0] RAM [0:MEMSIZE-1];
reg [RDATA_WIDTH-1:0] readB;

always @(posedge CLK)
begin
	if (WEN) begin
		RAM[WADDR] <= WDATA;
	end
end


always @(posedge CLK)
begin : ramread
	integer i;
	reg [log2RATIO-1:0] lsbaddr;
	if (REN) begin
		for (i = 0; i < RATIO; i = i+1) begin 
			lsbaddr = i;
			readB[(i+1)*minWIDTH-1 -: minWIDTH] <= RAM[{RADDR, lsbaddr}];
		end
	end
end
assign	RDATA = readB;

endmodule

