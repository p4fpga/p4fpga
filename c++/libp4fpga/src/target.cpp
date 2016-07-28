/*
Copyright 2015-2016 P4FPGA Project

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

// target implements IR::
//

#include <lib/cstring.h>

namespace {

class Target {
 protected:
    cstring name;
    explicit Target(cstring name) : name(name) {}
    Target() = delete;
    virtual ~Target() {}
 public:
    virtual void emit();
};

/*
// keep this strictly bsv related ...
//
class Parser : public Template {
    CodeBuilder*                    builder;
    BSV::Module*                    module;
    std::vector<BSV::Rule*>         rules;
    std::vector<BSV::Method*>       methods;
    std::vector<BSV::Function*>     functions;

    Parser(const CodeBuilder* builder) : builder(builder) {}
    void emit_vardecldo();
    void emit_fixed_rule();
    void emit_fixed_function();

 public:
    void build();
    void add_states(); 
}

void emit_vard(Expr) {
    auto vardo = BSV::Vardo();
    auto rule = BSV::Rule();
}

void build() {
    vardo = buildVarDeclDo();
    rules = buildTemplateRules();
    methods = buildTemplateMethods();
    module = BSV::Module(vardo, rules, methods);
}

void emit(CodeBuilder* builder) {
    for (auto r: rules) {
        r.emit();
    }
}

void build_funct_succeed(); // maps to nothing.
void build_funct_fetch_next_header(); // maps to nothing.
void build_funct_move_shift_amt();  // maps to nothing.
void build_funct_failed_and_trap(); // maps to nothings.
void build_funct_report_parse_action(); // maps to nothing
void build_rule_start(); // maps to nothing.
void build_rule_data_ff_load(); // maps to nothing.

void build_funct_push_phv(); // maps to usermetadata
void build_funct_transition(); // maps to SelectExpression
void build_rule_state_load(); // maps to components
void build_rule_state_extract(); // maps to components
void build_rule_state_transitions(); // maps to PathExpression or SelectExpression
void build_mutually_exclusive_attribute(); // maps to nothing.
void build_vardecldo(); // maps to nothing
void build_phv(); // maps to nothing.

void emit_interface(); // module
void emit_module(); //
    -- emit_vardo();
    -- emit_functions();
    -- emit_rules();
    -- emit_methods();

*/

}
