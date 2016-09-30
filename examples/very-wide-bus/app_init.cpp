#include "GeneratedTypes.h"
#include "MainRequest.h"

void app_init (MainRequestProxy* device) {
    ForwardReqT key = {0x00000001};
    ForwardRspT val = {1, 0xbabeabbe};
    device->forward_add_entry(key, val);
}
