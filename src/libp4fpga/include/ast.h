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

#include "ir/ir.h"

namespace Bluespec {

class BSVObject {
 public:
    virtual ~BSVObject() {};
    virtual void emit(CodeBuilder *builder) = 0;
    template<typename T> bool is() const { return to<T>() != nullptr; }
    template<typename T> const T* to() const {
        return dynamic_cast<const T*>(this); }
    template<typename T> T* to() {
        return dynamic_cast<T*>(this); }
};

class Method : public BSVObject {
 public:
    explicit Method(/* name, rtype, params, stmt */);
    void emit(CodeBuilder* builder) override;
};

class ActionBlock : public BSVObject {
 public:
    explicit ActionBlock(/* */);
    void emit(CodeBuilder* builder) override;
}

class ActionValueBlock: public BSVObject {
 public:
    explicit ActionValueBlock(/* */);
    void emit(CodeBuilder* builder) override;
}

class Function: public BSVObject {
 public:
    explicit Function(/* */);
    void emit(CodeBuilder* builder) override;
}

class Interface: public BSVObject {
 public:
    explicit Interface(/* */);
    void emit(CodeBuilder* builder) override;
}

class TypeClass: public BSVObject {
 public:
    explicit TypeClass(/* */);
    void emit(CodeBuilder* builder) override;
}

class Module: public BSVObject {
 public:
    explicit Module(/* */);
    void emit(CodeBuilder* builder) override;
}

class Rule: public BSVObject {
 public:
    explicit Rule(/* */);
    void emit(CodeBuilder* builder) override;
}

class Enum: public BSVObject {
 public:
    explicit Enum(/* */);
    void emit(CodeBuilder* builder) override;
}

class Struct: public BSVObject {
 public:
    explicit Struct(/* */);
    void emit(CodeBuilder* builder) override;
}

// TypeDef
// Param
// Type
// Case
// If
// ElseIf
// Else
// Instance
}
