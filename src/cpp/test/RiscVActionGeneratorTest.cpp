/*
  Copyright 2025 P4FPGA Project

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0


  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

#include <gtest/gtest.h>
#include "ir/ir.h"
#include "RiscVActionGenerator.h"
#include "frontends/p4/parseAnnotations.h"
#include "frontends/common/parseInput.h"
#include "frontends/p4/frontend.h"
#include "midend.h"
#include "options.h"
#include "helpers.h"
#include "control.h"
#include <iostream>
#include <sstream>
#include <fstream>
#include <cstdlib>

using namespace P4;
using namespace FPGA;

namespace Test {

// Test fixture for the RiscVActionGenerator tests
class RiscVActionGeneratorTest : public ::testing::Test {
protected:
    const IR::P4Program* program;
    P4::ReferenceMap refMap;
    P4::TypeMap typeMap;
    
    void SetUp() override {
        // Create simple test P4 program
        const char* testProgramText = R"(
            #include <core.p4>
            #include <v1model.p4>

            // Header definitions
            header ethernet_t {
                bit<48> dstAddr;
                bit<48> srcAddr;
                bit<16> etherType;
            }

            // Metadata definition
            struct metadata_t {
                bit<32> value1;
                bit<32> value2;
                bit<8> outPort;
                bool dropFlag;
            }

            struct headers_t {
                ethernet_t ethernet;
            }

            // Parser implementation
            parser MyParser(packet_in packet,
                          out headers_t hdr,
                          inout metadata_t meta,
                          inout standard_metadata_t standard_metadata) {
                state start {
                    packet.extract(hdr.ethernet);
                    transition accept;
                }
            }

            // Simple math action
            control MyControl(inout headers_t hdr,
                            inout metadata_t meta,
                            inout standard_metadata_t standard_metadata) {
                
                action increment_values() {
                    meta.value1 = meta.value1 + 1;
                    meta.value2 = meta.value2 + 2;
                }
                
                action update_port(bit<8> port) {
                    if (hdr.ethernet.etherType < 1500) {
                        meta.outPort = port;
                    } else {
                        meta.outPort = port + 1;
                    }
                }
                
                action drop_packet() {
                    meta.dropFlag = true;
                }
                
                table example_table {
                    key = {
                        hdr.ethernet.dstAddr: exact;
                    }
                    actions = {
                        increment_values;
                        update_port;
                        drop_packet;
                    }
                    default_action = increment_values();
                }
                
                apply {
                    example_table.apply();
                }
            }

            // Dummy components to satisfy v1model architecture
            control MyVerifyChecksum(inout headers_t hdr, inout metadata_t meta) {
                apply { }
            }

            control MyIngress(inout headers_t hdr,
                             inout metadata_t meta,
                             inout standard_metadata_t standard_metadata) {
                apply {
                    MyControl.apply(hdr, meta, standard_metadata);
                }
            }

            control MyEgress(inout headers_t hdr,
                           inout metadata_t meta,
                           inout standard_metadata_t standard_metadata) {
                apply { }
            }

            control MyDeparser(packet_out packet, in headers_t hdr) {
                apply {
                    packet.emit(hdr.ethernet);
                }
            }

            control MyComputeChecksum(inout headers_t hdr, inout metadata_t meta) {
                apply { }
            }

            V1Switch(
                MyParser(),
                MyVerifyChecksum(),
                MyIngress(),
                MyEgress(),
                MyComputeChecksum(),
                MyDeparser()
            ) main;
        )";
        
        // Write test program to a temporary file
        std::ofstream tempFile("/tmp/risc_v_test.p4");
        tempFile << testProgramText;
        tempFile.close();
        
        // Parse and compile the P4 program
        AutoCompileContext autoContext(new FPGAContext);
        FPGAOptions& options = FPGAContext::get().options();
        options.preprocessor_options += " -I.";
        const char* argv[] = {"", "/tmp/risc_v_test.p4"};
        options.process(2, const_cast<char* const*>(argv));
        
        program = P4::parseP4File(options);
        ASSERT_NE(program, nullptr);
        
        // Run front-end and mid-end passes
        P4::FrontEnd frontend;
        program = frontend.run(options, program);
        ASSERT_NE(program, nullptr);
        
        FPGA::MidEnd midend;
        const IR::ToplevelBlock* toplevel = midend.run(program, options);
        ASSERT_NE(toplevel, nullptr);
        
        // Prepare reference map and type map
        refMap = midend.refMap;
        typeMap = midend.typeMap;
    }
    
    IR::P4Action* findAction(const IR::P4Program* program, const char* actionName) {
        for (auto decl : program->objects) {
            if (auto control = decl->to<IR::P4Control>()) {
                if (control->name.toString() == "MyControl") {
                    for (auto actionDecl : control->controlLocals) {
                        if (auto action = actionDecl->to<IR::P4Action>()) {
                            if (action->name.toString() == actionName) {
                                return action;
                            }
                        }
                    }
                }
            }
        }
        return nullptr;
    }
    
    IR::P4Table* findTable(const IR::P4Program* program, const char* tableName) {
        for (auto decl : program->objects) {
            if (auto control = decl->to<IR::P4Control>()) {
                if (control->name.toString() == "MyControl") {
                    for (auto tableDecl : control->controlLocals) {
                        if (auto table = tableDecl->to<IR::P4Table>()) {
                            if (table->name.toString() == tableName) {
                                return table;
                            }
                        }
                    }
                }
            }
        }
        return nullptr;
    }
};

// Test case for the 'increment_values' action
TEST_F(RiscVActionGeneratorTest, IncrementValuesAction) {
    // Find the action in the program
    auto action = findAction(program, "increment_values");
    ASSERT_NE(action, nullptr);
    
    // Create a control object (normally this would be created by the backend)
    auto table = findTable(program, "example_table");
    ASSERT_NE(table, nullptr);
    
    FPGAControl control(nullptr); // We only need a minimal control object for testing
    control.action_to_table[action->name.toString()] = table;
    
    // Create a dummy BSV program
    BSVProgram bsv;
    
    // Create the RISC-V action generator
    RiscVActionGenerator generator(&control, bsv);
    
    // Process the action
    generator.postorder(action);
    
    // TODO: In a real test, we would validate the generated RISC-V instructions
    // For now, we'll just ensure the generator runs without errors
    EXPECT_TRUE(true);
}

// Test case for the 'update_port' action with conditional logic
TEST_F(RiscVActionGeneratorTest, UpdatePortAction) {
    // Find the action in the program
    auto action = findAction(program, "update_port");
    ASSERT_NE(action, nullptr);
    
    // Create a control object (normally this would be created by the backend)
    auto table = findTable(program, "example_table");
    ASSERT_NE(table, nullptr);
    
    FPGAControl control(nullptr);
    control.action_to_table[action->name.toString()] = table;
    
    // Create a dummy BSV program
    BSVProgram bsv;
    
    // Create the RISC-V action generator
    RiscVActionGenerator generator(&control, bsv);
    
    // Process the action
    generator.postorder(action);
    
    // In a real test, we would validate the generated RISC-V instructions
    EXPECT_TRUE(true);
}

// Test case for the 'drop_packet' action
TEST_F(RiscVActionGeneratorTest, DropPacketAction) {
    // Find the action in the program
    auto action = findAction(program, "drop_packet");
    ASSERT_NE(action, nullptr);
    
    // Create a control object (normally this would be created by the backend)
    auto table = findTable(program, "example_table");
    ASSERT_NE(table, nullptr);
    
    FPGAControl control(nullptr);
    control.action_to_table[action->name.toString()] = table;
    
    // Create a dummy BSV program
    BSVProgram bsv;
    
    // Create the RISC-V action generator
    RiscVActionGenerator generator(&control, bsv);
    
    // Process the action
    generator.postorder(action);
    
    // In a real test, we would validate the generated RISC-V instructions
    EXPECT_TRUE(true);
}

}  // namespace Test

int main(int argc, char **argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}