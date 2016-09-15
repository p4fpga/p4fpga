#ifndef _BACKENDS_P4_RESOURCE_H_
#define _BACKENDS_P4_RESOURCE_H_

#include "ir/ir.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "frontends/p4/methodInstance.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "bsvprogram.h"

namespace P4 {

class DoResourceEstimation : public Inspector {
  // temporary variables to pass values
  cstring table_name;
  cstring table_type;
  int width_bit;
  int table_size;
  FPGA::Profiler*     profgen;
  const ReferenceMap* refMap;
  const TypeMap*      typeMap;
 public:
  DoResourceEstimation(const ReferenceMap* refMap, const TypeMap* typeMap, FPGA::Profiler* profgen) :
          refMap(refMap), typeMap(typeMap), profgen(profgen)
  { CHECK_NULL(refMap); CHECK_NULL(typeMap); setName("DoResourceEstimation"); }
  bool preorder(const IR::P4Table* table) override;
  bool preorder(const IR::P4Control* table) override;
  bool preorder(const IR::ActionList* actions) override;
  bool preorder(const IR::Key* actions) override;
};

class ResourceEstimation: public PassManager {
 public:
  ResourceEstimation(ReferenceMap* refMap, TypeMap* typeMap, FPGA::Profiler* profgen) {
    passes.push_back(new TypeChecking(refMap, typeMap));
    passes.push_back(new DoResourceEstimation(refMap, typeMap, profgen));
    setName("Resource Estimation");
  }
};

}  // namespace P4

#endif /* _BACKENDS_P4_RESOURCE_H_ */

