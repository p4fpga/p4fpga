/* Copyright (c) 2016 Cornell University
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

#include <iostream>
#include <unordered_map>

#ifdef __cplusplus
extern "C" {
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

typedef uint64_t RoutingReqT;
typedef uint16_t RoutingRespT;

std::unordered_map<RoutingReqT, RoutingRespT> routing_table;

extern "C" RoutingRespT matchtable_read_routing(RoutingReqT rdata)
{
    fprintf(stderr, "CPP: match table read %lx\n", rdata);
    for( const auto& n : routing_table) {
        fprintf(stderr, "READ: Key:[%lx] Value:[%x]\n", n.first, n.second);
    }
    fprintf(stderr, "accessing table %p with key %lx\n", &routing_table, rdata);
    auto it = routing_table.find(rdata);
    if (it != routing_table.end()) {
        return routing_table[rdata];
    } else {
        return 0;
    }
}

extern "C" void matchtable_write_routing(RoutingReqT wdata, RoutingRespT action)
{
    fprintf(stderr, "CPP: match table write %lx %x\n", wdata, action);
    routing_table[wdata] = action;
    for( const auto& n : routing_table ) {
        fprintf(stderr, "WRITE: Key:[%lx] Value:[%x]\n", n.first, n.second);
    }
}

#ifdef __cplusplus
}
#endif
