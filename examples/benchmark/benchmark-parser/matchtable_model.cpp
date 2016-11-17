#include <iostream>
#include <unordered_map>
#ifdef __cplusplus
extern "C" {
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
typedef uint64_t ForwardTableReqT;
typedef uint64_t ForwardTableRspT;
std::unordered_map<ForwardTableReqT, ForwardTableRspT> tbl_forward_table;
extern "C" ForwardTableReqT matchtable_read_forward_table(ForwardTableReqT rdata) {
    auto it = tbl_forward_table.find(rdata);
    if (it != tbl_forward_table.end()) {
        return tbl_forward_table[rdata];
    } else {
        return 0;
    }
}
extern "C" void matchtable_write_forward_table(ForwardTableReqT wdata, ForwardTableRspT action){
    tbl_forward_table[wdata] = action;
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
