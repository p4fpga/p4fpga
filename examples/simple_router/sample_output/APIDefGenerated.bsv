method Action forward_add_entry(ForwardReqT key, ForwardRspT nhop_ipv4);
method Action ipv4_lpm_add_entry(Ipv4LpmReqT key, Ipv4LpmRspT dstAddr);
method Action send_frame_add_entry(SendFrameReqT key, SendFrameRspT egress_port);
