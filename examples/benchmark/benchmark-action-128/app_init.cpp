#include "GeneratedTypes.h"
#include "MainRequest.h"

void app_init (MainRequestProxy* device) {
  ForwardTableReqT key = {0, 0x000cc47aa32535};
  ForwardTableRspT val = {1};
  fprintf(stderr, "insert table entry\n");
  device->forward_table_add_entry(key, val);

  TestTblReqT udp_key = {0, 0x9091};
  TestTblRspT udp_val = {1};
  device->test_tbl_add_entry(udp_key, udp_val);

//  SendFrameReqT sendFrame_key = {1};
//  SendFrameRspT sendFrame_val = {1, 0xaabbcceeddff};
//  device->send_frame_add_entry(sendFrame_key, sendFrame_val);
}
