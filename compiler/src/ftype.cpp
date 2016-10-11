#include "ftype.h"
#include "bsvprogram.h"

namespace FPGA {

FPGATypeFactory* FPGATypeFactory::instance;

FPGAType* FPGATypeFactory::create(const IR::Type* type) {
    CHECK_NULL(type);
    CHECK_NULL(typeMap);
    FPGAType* result = nullptr;
    if (type->is<IR::Type_Boolean>()) {
        result = new FPGABoolType();
    } else if (type->is<IR::Type_Bits>()) {
        result = new FPGAScalarType(type->to<IR::Type_Bits>());
    } else if (type->is<IR::Type_StructLike>()) {
        result = new FPGAStructType(type->to<IR::Type_StructLike>());
    } else if (type->is<IR::Type_Typedef>()) {
        auto canon = typeMap->getType(type);
        result = create(canon);
        auto path = new IR::Path(type->to<IR::Type_Typedef>()->name);
        result = new FPGATypeName(new IR::Type_Name(Util::SourceInfo(), path), result);
    } else if (type->is<IR::Type_Name>()) {
        auto canon = typeMap->getType(type);
        result = create(canon);
        result = new FPGATypeName(type->to<IR::Type_Name>(), result);
    } else {
        // TODO: need to support header stack
        ::error("Type %1% unsupported by FPGA", type);
    }

    return result;
}

void
FPGABoolType::declare(BSVProgram & bsv, cstring id, bool asPointer) {
    emit(bsv);
    if (asPointer)
        bsv.getParserBuilder().append("*");
    bsv.getParserBuilder().appendFormat(" %s", id.c_str());
}

unsigned FPGAScalarType::alignment() const {
    if (width <= 8)
        return 1;
    else if (width <= 16)
        return 2;
    else if (width <= 32)
        return 4;
    else
        // compiled as char*
        return 1;
}

void FPGAScalarType::emit(BSVProgram & bsv) {
    auto prefix = isSigned ? "i" : "u";

    if (width <= 8)
        bsv.getParserBuilder().appendFormat("%s8", prefix);
    else if (width <= 16)
        bsv.getParserBuilder().appendFormat("%s16", prefix);
    else if (width <= 32)
        bsv.getParserBuilder().appendFormat("%s32", prefix);
    else
        bsv.getParserBuilder().appendFormat("char*");
}

void
FPGAScalarType::declare(BSVProgram & bsv, cstring id, bool asPointer) {
    if (width <= 32) {
        emit(bsv);
        if (asPointer)
            bsv.getParserBuilder().append("*");
        bsv.getParserBuilder().spc();
        bsv.getParserBuilder().append(id);
    } else {
        if (asPointer)
            bsv.getParserBuilder().append("char*");
        else
            bsv.getParserBuilder().appendFormat("char %s[%d]", id.c_str(), bytesRequired());
    }
}

//////////////////////////////////////////////////////////

FPGAStructType::FPGAStructType(const IR::Type_StructLike* strct) :
        FPGAType(strct) {
    if (strct->is<IR::Type_Struct>())
        kind = "struct";
    else if (strct->is<IR::Type_Header>())
        kind = "struct";
    else if (strct->is<IR::Type_Union>())
        kind = "union";
    else
        BUG("Unexpected struct type %1%", strct);
    name = strct->name.name;
    width = 0;
    implWidth = 0;

    for (auto f : *strct->fields) {
        auto type = FPGATypeFactory::instance->create(f->type);
        auto wt = dynamic_cast<IHasWidth*>(type);
        if (wt == nullptr) {
            ::error("FPGA: Unsupported type in struct %s", f->type);
        } else {
            width += wt->widthInBits();
            implWidth += wt->implementationWidthInBits();
        }
        fields.push_back(new FPGAField(type, f));
    }
}

void
FPGAStructType::declare(BSVProgram & bsv, cstring id, bool asPointer) {
    bsv.getParserBuilder().append(kind);
    if (asPointer)
        bsv.getParserBuilder().append("*");
    const char* n = name.c_str();
    bsv.getParserBuilder().appendFormat(" %s %s", n, id.c_str());
}

void FPGAStructType::emit(BSVProgram & bsv) {
    bsv.getParserBuilder().emitIndent();
    bsv.getParserBuilder().append(kind);
    bsv.getParserBuilder().spc();
    bsv.getParserBuilder().append(name);
    bsv.getParserBuilder().spc();
    bsv.getParserBuilder().blockStart();

    for (auto f : fields) {
        auto type = f->type;
        bsv.getParserBuilder().emitIndent();

        type->declare(bsv, f->field->name, false);
        bsv.getParserBuilder().append("; ");
        bsv.getParserBuilder().append("/* ");
        bsv.getParserBuilder().append(type->type->toString());
        bsv.getParserBuilder().append(" */");
        bsv.getParserBuilder().newline();
    }

    if (type->is<IR::Type_Header>()) {
        bsv.getParserBuilder().emitIndent();
        auto type = FPGATypeFactory::instance->create(IR::Type_Boolean::get());
        type->declare(bsv, "ebpf_valid", false);
        bsv.getParserBuilder().endOfStatement(true);
    }

    bsv.getParserBuilder().blockEnd(false);
    bsv.getParserBuilder().endOfStatement(true);
}

///////////////////////////////////////////////////////////////

void FPGATypeName::declare(BSVProgram & bsv, cstring id, bool asPointer) {
    canonical->declare(bsv, id, asPointer);
}

unsigned FPGATypeName::widthInBits() {
    auto wt = dynamic_cast<IHasWidth*>(canonical);
    if (wt == nullptr) {
        ::error("Type %1% does not have a fixed witdh", type);
        return 0;
    }
    return wt->widthInBits();
}

unsigned FPGATypeName::implementationWidthInBits() {
    auto wt = dynamic_cast<IHasWidth*>(canonical);
    if (wt == nullptr) {
        ::error("Type %1% does not have a fixed witdh", type);
        return 0;
    }
    return wt->implementationWidthInBits();
}

}  // namespace FPGA
