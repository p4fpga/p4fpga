#include <iostream>
#include <unordered_map>
#ifdef __cplusplus
extern "C" {
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
typedef uint64_t ForwardReqT;
typedef uint64_t ForwardRspT;
std::unordered_map<ForwardReqT, ForwardRspT> tbl_forward;
extern "C" ForwardReqT matchtable_read_forward(ForwardReqT rdata) {
    auto it = tbl_forward.find(rdata);
    if (it != tbl_forward.end()) {
        return tbl_forward[rdata];
    } else {
        return 0;
    }
}
extern "C" void matchtable_write_forward(ForwardReqT wdata, ForwardRspT action){
    tbl_forward[wdata] = action;
}
typedef uint64_t Ipv4LpmReqT;
typedef uint64_t Ipv4LpmRspT;
std::unordered_map<Ipv4LpmReqT, Ipv4LpmRspT> tbl_ipv4_lpm;
extern "C" Ipv4LpmReqT matchtable_read_ipv4_lpm(Ipv4LpmReqT rdata) {
    auto it = tbl_ipv4_lpm.find(rdata);
    if (it != tbl_ipv4_lpm.end()) {
        return tbl_ipv4_lpm[rdata];
    } else {
        return 0;
    }
}
extern "C" void matchtable_write_ipv4_lpm(Ipv4LpmReqT wdata, Ipv4LpmRspT action){
    tbl_ipv4_lpm[wdata] = action;
}
#ifdef __cplusplus
}
#endif
#include <iostream>
#include <unordered_map>
#ifdef __cplusplus
extern "C" {
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
typedef uint64_t SendFrameReqT;
typedef uint64_t SendFrameRspT;
std::unordered_map<SendFrameReqT, SendFrameRspT> tbl_send_frame;
extern "C" SendFrameReqT matchtable_read_send_frame(SendFrameReqT rdata) {
    auto it = tbl_send_frame.find(rdata);
    if (it != tbl_send_frame.end()) {
        return tbl_send_frame[rdata];
    } else {
        return 0;
    }
}
extern "C" void matchtable_write_send_frame(SendFrameReqT wdata, SendFrameRspT action){
    tbl_send_frame[wdata] = action;
}
#ifdef __cplusplus
}
#endif
