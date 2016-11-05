#include "GeneratedTypes.h"
#include "MainRequest.h"

void app_init (MainRequestProxy* device) {
  ForwardReqT key = {0, 0x0a000001};
  ForwardRspT val = {1, 0xbabeabbe};
  device->forward_add_entry(key, val);

  Ipv4LpmReqT ipv4_key = {0, 0x0a000002};
  Ipv4LpmRspT ipv4_val = {1, 1, 0x0a000001};
  device->ipv4_lpm_add_entry(ipv4_key, ipv4_val);

  SendFrameReqT sendFrame_key = {1};
  SendFrameRspT sendFrame_val = {0, 0xaabbcceeddff};
  device->send_frame_add_entry(sendFrame_key, sendFrame_val);
}
