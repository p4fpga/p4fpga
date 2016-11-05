#include "GeneratedTypes.h"
#include "MainRequest.h"

#define TABLE_INSERT(n) \
  Table##n##ReqT key##n = {0, 0x003417eb96bf1c}; \
  Table##n##RspT val##n = {1}; \
  fprintf(stderr, "insert table entry\n"); \
  device->table_##n##_add_entry(key##n, val##n);

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

  TABLE_INSERT(1);
  TABLE_INSERT(2);
  TABLE_INSERT(3);
  TABLE_INSERT(4);
  TABLE_INSERT(5);
  TABLE_INSERT(6);
  TABLE_INSERT(7);
}
