#pragma once
#ifndef EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_CODEGENINSPECTOR_H_
#define EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_CODEGENINSPECTOR_H_

#include "bsvprogram.h"

namespace FPGA {

// This visitor is invoked on various subtrees
class CodeGenInspector : public Inspector {
 protected:
    BSVProgram & bsv_;
    const P4::TypeMap* typeMap;

 public:
  CodeGenInspector(BSVProgram & bsv, const P4::TypeMap* typeMap) :
    bsv_(bsv), typeMap(typeMap) { visitDagOnce = false; }

  using Inspector::preorder;

  bool preorder(const IR::Constant* expression) override;
  bool preorder(const IR::Declaration_Variable* decl) override;
  bool preorder(const IR::BoolLiteral* b) override;
  bool preorder(const IR::Cast* c) override;
  bool preorder(const IR::Operation_Binary* b) override;
  bool preorder(const IR::Operation_Unary* u) override;
  bool preorder(const IR::ArrayIndex* a) override;
  bool preorder(const IR::Mux* a) override;
  bool preorder(const IR::Member* e) override;
  bool comparison(const IR::Operation_Relation* comp);
  bool preorder(const IR::Equ* e) override { return comparison(e); }
  bool preorder(const IR::Neq* e) override { return comparison(e); }

  bool preorder(const IR::IndexedVector<IR::StatOrDecl>* v) override;
  bool preorder(const IR::Path* path) override;

  bool preorder(const IR::Type_Typedef* type) override;
  bool preorder(const IR::Type_Enum* type) override;
  bool preorder(const IR::AssignmentStatement* s) override;
  bool preorder(const IR::BlockStatement* s) override;
  bool preorder(const IR::MethodCallStatement* s) override;
  bool preorder(const IR::EmptyStatement* s) override;
  bool preorder(const IR::ReturnStatement* s) override;
  bool preorder(const IR::ExitStatement* s) override;
  bool preorder(const IR::IfStatement* s) override;

  void widthCheck(const IR::Node* node) const;

 protected:
  struct VecPrint {
    cstring separator;
    cstring terminator;

  VecPrint(const char* sep, const char* term) :
    separator(sep), terminator(term) {}
  };

  // maintained as stack
  std::vector<VecPrint> vectorSeparator;

  void setVecSep(const char* sep, const char* term = nullptr) {
    vectorSeparator.push_back(VecPrint(sep, term));
  }
  void doneVec() {
    BUG_CHECK(!vectorSeparator.empty(), "Empty vectorSeparator");
    vectorSeparator.pop_back();
  }
  VecPrint getSep() {
    BUG_CHECK(!vectorSeparator.empty(), "Empty vectorSeparator");
    return vectorSeparator.back();
  }
};

}  // namespace FPGA

#endif /* EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_CODEGENINSPECTOR_H_ */
