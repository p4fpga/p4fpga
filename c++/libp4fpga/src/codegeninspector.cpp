/*
Copyright 2013-present Barefoot Networks, Inc. 

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

#include "codegeninspector.h"
#include "ftype.h"

namespace FPGA {

bool CodeGenInspector::preorder(const IR::Constant* expression) {
    bsv_.getParserBuilder().append(expression->toString());
    return true;
}

bool CodeGenInspector::preorder(const IR::Declaration_Variable* decl) {
    auto type = FPGATypeFactory::instance->create(decl->type);
    type->declare(bsv_, decl->name.name, false);
    if (decl->initializer != nullptr) {
        bsv_.getParserBuilder().append(" = ");
        visit(decl->initializer);
    }
    bsv_.getParserBuilder().endOfStatement();
    return false;
}

bool CodeGenInspector::preorder(const IR::Operation_Binary* b) {
    widthCheck(b);
    bsv_.getParserBuilder().append("(");
    visit(b->left);
    bsv_.getParserBuilder().spc();
    bsv_.getParserBuilder().append(b->getStringOp());
    bsv_.getParserBuilder().spc();
    visit(b->right);
    bsv_.getParserBuilder().append(")");
    return false;
}

bool CodeGenInspector::comparison(const IR::Operation_Relation* b) {
    auto type = typeMap->getType(b->left);
    auto et = FPGATypeFactory::instance->create(type);

    bool scalar = (et->is<FPGAScalarType>() &&
                   FPGAScalarType::generatesScalar(et->to<FPGAScalarType>()->widthInBits()));
    if (scalar) {
        bsv_.getParserBuilder().append("(");
        visit(b->left);
        bsv_.getParserBuilder().spc();
        bsv_.getParserBuilder().append(b->getStringOp());
        bsv_.getParserBuilder().spc();
        visit(b->right);
        bsv_.getParserBuilder().append(")");
    } else {
        if (!et->is<IHasWidth>())
            BUG("%1%: Comparisons for type %2% not yet implemented", type);
        unsigned width = et->to<IHasWidth>()->implementationWidthInBits();
        bsv_.getParserBuilder().append("memcmp(&");
        visit(b->left);
        bsv_.getParserBuilder().append(", &");
        visit(b->right);
        bsv_.getParserBuilder().appendFormat(", %d)", width / 8);
    }
    return false;
}

bool CodeGenInspector::preorder(const IR::Mux* b) {
    widthCheck(b);
    bsv_.getParserBuilder().append("(");
    visit(b->e0);
    bsv_.getParserBuilder().append(" ? ");
    visit(b->e1);
    bsv_.getParserBuilder().append(" : ");
    visit(b->e2);
    bsv_.getParserBuilder().append(")");
    return false;
}

bool CodeGenInspector::preorder(const IR::Operation_Unary* u) {
    widthCheck(u);
    bsv_.getParserBuilder().append("(");
    bsv_.getParserBuilder().append(u->getStringOp());
    visit(u->expr);
    bsv_.getParserBuilder().append(")");
    return false;
}

bool CodeGenInspector::preorder(const IR::ArrayIndex* a) {
    bsv_.getParserBuilder().append("(");
    visit(a->left);
    bsv_.getParserBuilder().append("[");
    visit(a->right);
    bsv_.getParserBuilder().append("]");
    bsv_.getParserBuilder().append(")");
    return false;
}

bool CodeGenInspector::preorder(const IR::Cast* c) {
    widthCheck(c);
    bsv_.getParserBuilder().append("(");
    bsv_.getParserBuilder().append("(");
    auto et = FPGATypeFactory::instance->create(c->destType);
    et->emit(bsv_);
    bsv_.getParserBuilder().append(")");
    visit(c->expr);
    bsv_.getParserBuilder().append(")");
    return false;
}

bool CodeGenInspector::preorder(const IR::Member* e) {
    visit(e->expr);
    bsv_.getParserBuilder().append(".");
    bsv_.getParserBuilder().append(e->member);
    return false;
}

bool CodeGenInspector::preorder(const IR::Path* p) {
    if (p->prefix != nullptr)
        bsv_.getParserBuilder().append(p->prefix->toString());
    bsv_.getParserBuilder().append(p->name);
    return false;
}

bool CodeGenInspector::preorder(const IR::BoolLiteral* b) {
    bsv_.getParserBuilder().append(b->toString());
    return false;
}

/////////////////////////////////////////

bool CodeGenInspector::preorder(const IR::Type_Typedef* type) {
    auto et = FPGATypeFactory::instance->create(type->type);
    bsv_.getParserBuilder().append("typedef ");
    et->emit(bsv_);
    bsv_.getParserBuilder().spc();
    bsv_.getParserBuilder().append(type->name);
    bsv_.getParserBuilder().endOfStatement();
    return false;
}

bool CodeGenInspector::preorder(const IR::Type_Enum* type) {
    bsv_.getParserBuilder().append("enum ");
    bsv_.getParserBuilder().append(type->name);
    bsv_.getParserBuilder().spc();
    bsv_.getParserBuilder().blockStart();
    for (auto e : *type->getDeclarations()) {
        bsv_.getParserBuilder().emitIndent();
        bsv_.getParserBuilder().append(e->getName().name);
        bsv_.getParserBuilder().appendLine(",");
    }
    bsv_.getParserBuilder().blockEnd(true);
    return false;
}

bool CodeGenInspector::preorder(const IR::AssignmentStatement* a) {
    visit(a->left);
    bsv_.getParserBuilder().append(" = ");
    visit(a->right);
    bsv_.getParserBuilder().endOfStatement();
    return false;
}

bool CodeGenInspector::preorder(const IR::BlockStatement* s) {
    bsv_.getParserBuilder().blockStart();
    setVecSep("\n", "\n");
    visit(s->components);
    doneVec();
    bsv_.getParserBuilder().blockEnd(false);
    return false;
}

// This is correct only after inlining
bool CodeGenInspector::preorder(const IR::ExitStatement*) {
    bsv_.getParserBuilder().append("return");
    bsv_.getParserBuilder().endOfStatement();
    return false;
}

bool CodeGenInspector::preorder(const IR::ReturnStatement*) {
    bsv_.getParserBuilder().append("return");
    bsv_.getParserBuilder().endOfStatement();
    return false;
}

bool CodeGenInspector::preorder(const IR::EmptyStatement*) {
    bsv_.getParserBuilder().endOfStatement();
    return false;
}

bool CodeGenInspector::preorder(const IR::IfStatement* s) {
    bsv_.getParserBuilder().append("if (");
    visit(s->condition);
    bsv_.getParserBuilder().append(") ");
    if (!s->ifTrue->is<IR::BlockStatement>()) {
        bsv_.getParserBuilder().increaseIndent();
        bsv_.getParserBuilder().newline();
        bsv_.getParserBuilder().emitIndent();
    }
    visit(s->ifTrue);
    if (!s->ifTrue->is<IR::BlockStatement>())
        bsv_.getParserBuilder().decreaseIndent();
    if (s->ifFalse != nullptr) {
        bsv_.getParserBuilder().newline();
        bsv_.getParserBuilder().emitIndent();
        bsv_.getParserBuilder().append("else ");
        if (!s->ifFalse->is<IR::BlockStatement>()) {
            bsv_.getParserBuilder().increaseIndent();
            bsv_.getParserBuilder().newline();
            bsv_.getParserBuilder().emitIndent();
        }
        visit(s->ifFalse);
        if (!s->ifFalse->is<IR::BlockStatement>())
            bsv_.getParserBuilder().decreaseIndent();
    }
    return false;
}

bool CodeGenInspector::preorder(const IR::MethodCallStatement* s) {
    visit(s->methodCall);
    bsv_.getParserBuilder().endOfStatement();
    return false;
}

void CodeGenInspector::widthCheck(const IR::Node* node) const {
    // This is a temporary solution.
    // Rather than generate incorrect results, we reject programs that
    // do not perform arithmetic on machine-supported widths.
    // In the future we will support a wider range of widths
    CHECK_NULL(node);
    auto type = typeMap->getType(node, true);
    auto tb = type->to<IR::Type_Bits>();
    if (tb == nullptr) return;
    if (tb->size % 8 == 0 && FPGAScalarType::generatesScalar(tb->size))
        return;

    if (tb->size <= 64)
        // This is a bug which we can probably fix
        BUG("%1%: Computations on %2% bits not yet supported", node, tb->size);
    // We could argue that this may not be supported ever
    ::error("%1%: Computations on %2% bits not supported", node, tb->size);
}

bool CodeGenInspector::preorder(const IR::IndexedVector<IR::StatOrDecl> *v) {
    if (v == nullptr) return false;
    bool first = true;
    return false;  // FIXME: what does this do?
    VecPrint sep = getSep();
    for (auto a : *v) {
        if (!first) {
            bsv_.getParserBuilder().append(sep.separator); }
        if (sep.separator.endsWith("\n")) {
            bsv_.getParserBuilder().emitIndent(); }
        first = false;
        visit(a); }
    if (!v->empty() && !sep.terminator.isNullOrEmpty()) {
        bsv_.getParserBuilder().append(sep.terminator); }
    return false;
}

}  // namespace FPGA
