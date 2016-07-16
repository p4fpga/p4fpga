#include "ftype.h"

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
        ::error("Type %1% unsupported by FPGA", type);
    }

    return result;
}

void
FPGABoolType::declare(CodeBuilder* builder, cstring id, bool asPointer) {
    emit(builder);
    if (asPointer)
        builder->append("*");
    builder->appendFormat(" %s", id.c_str());
}

//cstring FPGAType::toString(const Target* target) {
//    CodeBuilder builder(target);
//    emit(&builder);
//    return builder.toString();
//}

/////////////////////////////////////////////////////////////

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

void FPGAScalarType::emit(CodeBuilder* builder) {
    auto prefix = isSigned ? "i" : "u";

    if (width <= 8)
        builder->appendFormat("%s8", prefix);
    else if (width <= 16)
        builder->appendFormat("%s16", prefix);
    else if (width <= 32)
        builder->appendFormat("%s32", prefix);
    else
        builder->appendFormat("char*");
}

void
FPGAScalarType::declare(CodeBuilder* builder, cstring id, bool asPointer) {
    if (width <= 32) {
        emit(builder);
        if (asPointer)
            builder->append("*");
        builder->spc();
        builder->append(id);
    } else {
        if (asPointer)
            builder->append("char*");
        else
            builder->appendFormat("char %s[%d]", id.c_str(), bytesRequired());
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
FPGAStructType::declare(CodeBuilder* builder, cstring id, bool asPointer) {
    builder->append(kind);
    if (asPointer)
        builder->append("*");
    const char* n = name.c_str();
    builder->appendFormat(" %s %s", n, id.c_str());
}

void FPGAStructType::emitInitializer(CodeBuilder* builder) {
    builder->blockStart();
    if (type->is<IR::Type_Struct>() || type->is<IR::Type_Union>()) {
        for (auto f : fields) {
            builder->emitIndent();
            builder->appendFormat(".%s = ", f->field->name.name);
            f->type->emitInitializer(builder);
            builder->append(",");
            builder->newline();
        }
    } else if (type->is<IR::Type_Header>()) {
        builder->emitIndent();
        builder->appendLine(".ebpf_valid = 0");
    } else {
        BUG("Unexpected type %1%", type);
    }
    builder->blockEnd(false);
}

void FPGAStructType::emit(CodeBuilder* builder) {
    builder->emitIndent();
    builder->append(kind);
    builder->spc();
    builder->append(name);
    builder->spc();
    builder->blockStart();

    for (auto f : fields) {
        auto type = f->type;
        builder->emitIndent();

        type->declare(builder, f->field->name, false);
        builder->append("; ");
        builder->append("/* ");
        builder->append(type->type->toString());
        builder->append(" */");
        builder->newline();
    }

    if (type->is<IR::Type_Header>()) {
        builder->emitIndent();
        auto type = FPGATypeFactory::instance->create(IR::Type_Boolean::get());
        type->declare(builder, "ebpf_valid", false);
        builder->endOfStatement(true);
    }

    builder->blockEnd(false);
    builder->endOfStatement(true);
}

///////////////////////////////////////////////////////////////

void FPGATypeName::declare(CodeBuilder* builder, cstring id, bool asPointer) {
    canonical->declare(builder, id, asPointer);
}

void FPGATypeName::emitInitializer(CodeBuilder* builder) {
    canonical->emitInitializer(builder);
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
