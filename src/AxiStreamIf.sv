interface AxiStreamIf #(parameter int WIDTH = 8);
    logic               tvalid;
    logic               tlast;
    logic               tuser;
    logic [WIDTH-1:0]   tdata;
    logic               tready;

    modport Master (
                input  tready,
                output tvalid, tlast, tuser, tdata
            );

    modport Slave (
                input  tvalid, tlast, tuser, tdata,
                output tready
            );
endinterface