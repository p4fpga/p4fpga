#include "GeneratedTypes.h"
#include "MainRequest.h"

void app_init (MainRequestProxy* device) {
  ForwardTableReqT key = {0, 0x003417eb96bf1c};
  ForwardTableRspT val = {1};
  fprintf(stderr, "insert table entry\n");
  device->forward_table_add_entry(key, val);

  sleep(1);

  key = {0, 0x000cc47aa32535};
  val = {1};
  fprintf(stderr, "insert table entry\n");
  device->forward_table_add_entry(key, val);

  Table1ReqT key0 = {0, 0x003417eb96bf1c};
  Table1RspT val0 = {1};
  fprintf(stderr, "insert table entry\n");
  device->table_1_add_entry(key0, val0);

  Table2ReqT key2 = {0, 0x003417eb96bf1c};
  Table2RspT val2 = {1};
  device->table_2_add_entry(key2, val2);

//  Ipv4LpmReqT ipv4_key = {0, 0x0a000002};
//  Ipv4LpmRspT ipv4_val = {1, 1, 0x0a000001};
//  device->ipv4_lpm_add_entry(ipv4_key, ipv4_val);
//
//  SendFrameReqT sendFrame_key = {1};
//  SendFrameRspT sendFrame_val = {1, 0xaabbcceeddff};
//  device->send_frame_add_entry(sendFrame_key, sendFrame_val);
}
