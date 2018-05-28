package wifii_pkg;
  
  typedef struct {
    logic [1:0] Protocol_Version;
    logic [1:0] Type;
    logic [1:0] Subtype;
    logic to_DS;      // to the distributed system
    logic from_DS;    // exit from distributed system
    logic More_Frag;  // more fragmented frames to follow
    logic Retry;      // re-transmission
    logic Pwr_Mgt;    // station in power save mode
    logic More_Data;  // additional frames buffered for the dest
    logic WEP;        // data protected with WEP Algorithm
    logic Order;      // frames must be strictly ordered
  }frame_control_field;

endpackage
