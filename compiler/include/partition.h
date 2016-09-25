#ifndef _BACKENDS_P4_PARTITION_H_
#define _BACKENDS_P4_PARTITION_H_

#include "ir/ir.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "frontends/p4/methodInstance.h"
#include "frontends/common/resolveReferences/resolveReferences.h"

namespace P4 {

class DoPartition : public Transform {
    int n_table;
    bool start_partition;
    ReferenceMap* refMap;
    TypeMap*      typeMap;
    int tbegin;
    int tend;
 public:
    DoPartition(ReferenceMap* refMap, TypeMap* typeMap, const int tbegin, const int tend) :
            refMap(refMap), typeMap(typeMap), tbegin(tbegin), tend(tend)
    { CHECK_NULL(refMap); CHECK_NULL(typeMap); setName("DoPartition"); }
    const IR::Node* preorder(IR::BlockStatement* statement) override;
    const IR::Node* postorder(IR::BlockStatement* statement) override;
    const IR::Node* preorder(IR::IfStatement* statement) override;
    const IR::Node* postorder(IR::IfStatement* statement) override;
    const IR::Node* preorder(IR::MethodCallStatement* statement) override;
    const IR::Node* postorder(IR::MethodCallStatement* statement) override;
};

class Partition : public PassManager {
 public:
  Partition(ReferenceMap* refMap, TypeMap* typeMap, int tbegin, int tend) {
    passes.push_back(new TypeChecking(refMap, typeMap));
    passes.push_back(new DoPartition(refMap, typeMap, tbegin, tend));
    setName("Partition");
  }
};

}  // namespace P4

#endif /* _BACKENDS_P4_PARTITION_H_ */
