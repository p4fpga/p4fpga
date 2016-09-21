#include "GeneratedTypes.h"
#include "MainRequest.h"

void app_init (MainRequestProxy* device) {
    ForwardReqT key = {0x000a0001};
    ForwardRspT val = {1, 0xbabeabbe};
    device->forward_add_entry(key, val);

    Ipv4LpmReqT ipv4_key = {0x0a000002};
    Ipv4LpmRspT ipv4_val = {1, 0, 0x000a0001};
    device->ipv4_lpm_add_entry(ipv4_key, ipv4_val);

    SendFrameReqT send_frame_key = {0};
    SendFrameRspT send_frame_val = {1, 0xbabebabebe};
    device->send_frame_add_entry(send_frame_key, send_frame_val);
}
