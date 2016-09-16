#include <iostream>
#include <unordered_map>
#ifdef __cplusplus
extern "C" {
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
typedef uint64_t ForwardTblReqT;
typedef uint64_t ForwardTblRspT;
std::unordered_map<ForwardTblReqT, ForwardTblRspT> tbl_forward_tbl;
extern "C" ForwardTblReqT matchtable_read_forwardtbl(ForwardTblReqT rdata) {
    auto it = tbl_forward_tbl.find(rdata);
    if (it != tbl_forward_tbl.end()) {
        return tbl_forward_tbl[rdata];
    } else {
        return 0;
    }
}
extern "C" void matchtable_write_forwardtbl(ForwardTblReqT wdata, ForwardTblRspT action){
    tbl_forward_tbl[wdata] = action;
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
#ifdef __cplusplus
}
#endif
