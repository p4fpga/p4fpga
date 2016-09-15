// random code to test IR

#include "ir/ir.h"
#include "ftest.h"
#include "frontends/p4/coreLibrary.h"

namespace FPGA {

void Test::ir_toplevel() {
    auto package = toplevel->getMain();
    LOG1("build " << dumpToString(package));

    LOG1("model " << package->type->name);
    auto parserBlock = package->getParameterValue(v1model.sw.parser.name);
    auto parser  = parserBlock->to<IR::ParserBlock>()->container;
    LOG1("sw.parser " << parserBlock);
    // auto type = parser->type;
    LOG1("header idx " << v1model.parser.headersParam.index);
    auto hdr = parser->type->applyParams->getParameter(v1model.parser.headersParam.index);
    LOG1("hdr " << hdr);
    auto headersType = typeMap->getType(hdr->getNode(), true);
    auto ht = headersType->to<IR::Type_Struct>();
    for (auto f : *ht->fields) {
        LOG1("f " << f);
        LOG1("ftype " << typeMap->getType(f->type, true));
    }

    // user metdata
    auto userMetadataParam = parser->type->applyParams->getParameter(
            v1model.parser.metadataParam.index);
    LOG1("u " << userMetadataParam);
    auto mdType = typeMap->getType(userMetadataParam, true);
    LOG1("mdu " << mdType);
    auto mt = mdType->to<IR::Type_Struct>();
    for (auto m : *mt->fields) {
        LOG1("m: " << m->type);
        auto mdt = typeMap->getType(m->type, true);
        LOG1("mdt " << mdt);
        auto m_field = mdt->to<IR::Type_Struct>();
        CHECK_NULL(m_field);
        for (auto md : *m_field->fields) {
            LOG1("mdd: " << md);
        }
    }

    for (auto s : *parser->states) {
        auto sType = s->selectExpression;
        auto aType = s->annotations;
        if (s->name == IR::ParserState::accept || s->name == IR::ParserState::reject) {
            LOG1("s: " << s->name << " " << sType);
        } else if (sType->is<IR::SelectExpression>()) {
            auto se = sType->to<IR::SelectExpression>();
            for (auto sc : se->selectCases) {
                LOG1("case: " << sc);
                LOG1("keyset " << sc->keyset);
                LOG1("path go: " << sc->state);
            }
            LOG1("select: " << sType);
        } else if (sType->is<IR::PathExpression>()) {
            auto sp = sType->to<IR::PathExpression>();
            LOG1("path: " << sType);
            LOG1("path info: " << sp->path);
        }

        LOG1("annotation: " << aType);
        for (auto c : *s->components) {
            LOG1("c: " << c);
            if (c->is<IR::AssignmentStatement>()) {
                const IR::Expression *l, *r;
                auto assign = c->to<IR::AssignmentStatement>();
                l = (assign->left);
                r = (assign->right);
                LOG1("cc: " << l << r);
            } else {
                LOG1("else: " << c);
            }
        }
    }
}

void Test::build() {
    ir_toplevel();
}
}  // namespace FPGA
