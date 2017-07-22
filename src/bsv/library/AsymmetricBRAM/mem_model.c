/*-
 * Copyright (c) 2013, 2014 Alexandre Joannou
 * All rights reserved.
 *
 * This software was developed by SRI International and the University of
 * Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-10-C-0237
 * ("CTSRD"), as part of the DARPA CRASH research programme.
 *
 * @BERI_LICENSE_HEADER_START@
 *
 * Licensed to BERI Open Systems C.I.C. (BERI) under one or more contributor
 * license agreements.  See the NOTICE file distributed with this work for
 * additional information regarding copyright ownership.  BERI licenses this
 * file to you under the BERI Hardware-Software License, Version 1.0 (the
 * "License"); you may not use this file except in compliance with the
 * License.  You may obtain a copy of the License at:
 *
 *   http://www.beri-open-systems.org/legal/license-1-0.txt
 *
 * Unless required by applicable law or agreed to in writing, Work distributed
 * under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations under the License.
 *
 * @BERI_LICENSE_HEADER_END@
 */

#ifdef __cplusplus
extern "C" {
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

typedef struct {
    unsigned char ** data;
    unsigned int elementByteSize;
    unsigned int size;
    unsigned int ratio;
    unsigned int readElementSize;
    unsigned int writeElementSize;
} mem_t;

unsigned long long mem_create(unsigned int * memSize,
                              unsigned int * readElementSize,
                              unsigned int * writeElementSize)
{
    mem_t * m = (mem_t*) malloc (sizeof(mem_t));

    m->elementByteSize = ((*writeElementSize)%8)    ?
                         ((*writeElementSize)/8) + 1:
                         ((*writeElementSize)/8)    ;
    //fprintf(stderr, "writeElementSize=%d, elementByteSize=%x\n", *writeElementSize, m->elementByteSize);

    m->size = *memSize;

    m->ratio = ((*readElementSize)%(*writeElementSize))    ?
               ((*readElementSize)/(*writeElementSize)) + 1:
               ((*readElementSize)/(*writeElementSize))    ;
    m->readElementSize = *readElementSize;
    m->writeElementSize = *writeElementSize;

    m->data = (unsigned char **) malloc (*memSize * sizeof(unsigned char *));

    unsigned int i;
    for (i = 0; i < *memSize; i++)
    {
        m->data[i] = (unsigned char *) malloc (m->elementByteSize * sizeof(unsigned char));
    }
    unsigned int j, k;
    for (j=0; j<*memSize; j++) {
        for (k=0; k<m->elementByteSize; k++) {
            m->data[j][k] = 0;
        }
    }
    //fprintf(stderr, "memSize=%d, elemByteSize=%d\n", *memSize, m->elementByteSize);

    return (unsigned long long) m;
}

void mem_read(unsigned int * rdata_return, unsigned long long mem_ptr, unsigned int * rindex)
{
    mem_t * m = (mem_t*) mem_ptr;

    unsigned int return_size = ((m->readElementSize)%8) ?
                               ((m->readElementSize)/8) + 1:
                               ((m->readElementSize)/8);
    uint64_t output = 0;

    unsigned int base = (*rindex) * (m->ratio); //* (m->elementByteSize) 
    unsigned int i, j;
    //fprintf(stderr, "rindex=%x, ratio=%d, elementByteSize=%d\n", *rindex, m->ratio, m->elementByteSize);
    for (i = 0; i < (m->ratio); i++)
    {
        for (j = 0; j < m->elementByteSize; j++)
        {
            unsigned char bits = m->data[base+i][j];
            //fprintf(stderr, "%p: base=%x, offset=%x, bits=%x\n", m->data, base+i, j, bits);
            if (j!=(m->elementByteSize-1)) {
                int shift_a = i * (m->writeElementSize);
                output |= ((uint64_t)bits) << shift_a;
            } else {
                unsigned char mask = ((1 << (m->writeElementSize % 8)) - 1); 
                int shift_a = i * (m->writeElementSize);
                output |= ((uint64_t)(bits & mask) << ((m->elementByteSize-1)*8 + shift_a));
            }
        }
    }

    //fprintf(stderr, "read data=%llx\n", output);
    for (i=0; i<return_size; i++) {
        ((unsigned char*)(rdata_return))[i] = (output >> (i * 8)) & 0xFF;
    }
}

void mem_write(unsigned long long mem_ptr, unsigned int * windex, unsigned int * wdata)
{
    mem_t * m = (mem_t*) mem_ptr;

    unsigned int base = (*windex);// * (m->elementByteSize);
    unsigned int i;
    //fprintf(stderr, "write windex=%x, m->elementByteSize=%x\n", *windex, m->elementByteSize);
    for (i = 0; i < m->elementByteSize; i++)
    {
        //fprintf(stderr, "%p: write addr=%x, offset=%x, data=%x\n", m->data, base, i, ((unsigned char *)(wdata))[i]);
        m->data[base][i] = ((unsigned char *)(wdata))[i];
    }
}

void mem_clean(unsigned long long mem_ptr)
{
    mem_t * m = (mem_t*) mem_ptr;
    unsigned int i;
    for (i = 0; i < m->size; i++)
    {
        free(m->data[i]);
    }
    free(m);
}

#ifdef __cplusplus
}
#endif
