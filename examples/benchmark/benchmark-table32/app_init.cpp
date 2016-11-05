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
  TABLE_INSERT(8);
  TABLE_INSERT(9);
  TABLE_INSERT(10);
  TABLE_INSERT(11);
  TABLE_INSERT(12);
  TABLE_INSERT(13);
  TABLE_INSERT(14);
  TABLE_INSERT(15);
  TABLE_INSERT(16);
  TABLE_INSERT(17);
  TABLE_INSERT(18);
  TABLE_INSERT(19);
  TABLE_INSERT(20);
  TABLE_INSERT(21);
  TABLE_INSERT(22);
  TABLE_INSERT(23);
  TABLE_INSERT(24);
  TABLE_INSERT(25);
  TABLE_INSERT(26);
  TABLE_INSERT(27);
  TABLE_INSERT(28);
  TABLE_INSERT(29);
  TABLE_INSERT(30);
  TABLE_INSERT(31);
}
