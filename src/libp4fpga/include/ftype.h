
#ifndef EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_FTYPE_H_
#define EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_FTYPE_H_

#include "lib/algorithm.h"
#include "lib/sourceCodeBuilder.h"
#include "program.h"
#include "ir/ir.h"

namespace FPGA {

// Base class for FPGA types
class FPGAType : public FPGAObject {
 protected:
    explicit FPGAType(const IR::Type* type) : type(type) {}
 public:
    const IR::Type* type;
    virtual void emit(BSVProgram & bsv) = 0;
    virtual void declare(BSVProgram & bsv, cstring id, bool asPointer) = 0;
    // cstring toString(const Target* target);
};

class IHasWidth {
 public:
    virtual ~IHasWidth() {}
    // P4 width
    virtual unsigned widthInBits() = 0;
    // Width in the target implementation.
    // Currently a multiple of 8.
    virtual unsigned implementationWidthInBits() = 0;
};

class FPGATypeFactory {
 private:
    const P4::TypeMap* typeMap;
    explicit FPGATypeFactory(const P4::TypeMap* typeMap) : typeMap(typeMap) {}
 public:
    static FPGATypeFactory* instance;
    static void createFactory(const P4::TypeMap* typeMap)
    { FPGATypeFactory::instance = new FPGATypeFactory(typeMap); }
    FPGAType* create(const IR::Type* type);
};

class FPGABoolType : public FPGAType, IHasWidth {
 public:
    FPGABoolType() : FPGAType(IR::Type_Boolean::get()) {}
    void emit(BSVProgram & bsv) override
    { }
    void declare(BSVProgram & bsv,
                 cstring id, bool asPointer) override;
    unsigned widthInBits() override { return 1; }
    unsigned implementationWidthInBits() override { return 8; }
};

class FPGAScalarType : public FPGAType, public IHasWidth {
 public:
    const unsigned width;
    const bool     isSigned;
    explicit FPGAScalarType(const IR::Type_Bits* bits) :
            FPGAType(bits), width(bits->size), isSigned(bits->isSigned) {
    }
    unsigned bytesRequired() const { return ROUNDUP(width, 8); }
    unsigned alignment() const;
    void emit(BSVProgram & bsv) override;
    void declare(BSVProgram & bsv,
                 cstring id, bool asPointer) override;
    unsigned widthInBits() override { return width; }
    unsigned implementationWidthInBits() override { return bytesRequired() * 8; }
    // True if this width is small enough to store in a machine scalar
    static bool generatesScalar(unsigned width)
    { return width <= 32; }
};

// This should not always implement IHasWidth, but it may...
class FPGATypeName : public FPGAType, public IHasWidth {
    const IR::Type_Name* type;
    FPGAType* canonical;
 public:
    FPGATypeName(const IR::Type_Name* type, FPGAType* canonical) :
            FPGAType(type), type(type), canonical(canonical) {}
    void emit(BSVProgram & bsv) override { canonical->emit(bsv); }
    void declare(BSVProgram & bsv, cstring id, bool asPointer) override;
    unsigned widthInBits() override;
    unsigned implementationWidthInBits() override;
};

// Also represents headers and unions
class FPGAStructType : public FPGAType, public IHasWidth {
    class FPGAField {
     public:
        FPGAType* type;
        const IR::StructField* field;

        FPGAField(FPGAType* type, const IR::StructField* field) :
                type(type), field(field) {}
    };

 public:
    cstring  kind;
    cstring  name;
    std::vector<FPGAField*>  fields;
    unsigned width;
    unsigned implWidth;

    explicit FPGAStructType(const IR::Type_StructLike* strct);
    void declare(BSVProgram & bsv, cstring id, bool asPointer) override;
    unsigned widthInBits() override { return width; }
    unsigned implementationWidthInBits() override { return implWidth; }
    void emit(BSVProgram & bsv) override;
};


}  // namespace FPGA

#endif /* EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_FTYPE_H_ */
