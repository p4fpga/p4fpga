#include "options.h"
#include "ir/ir.h"
#include "midend.h"
#include "frontends/p4/actionsInlining.h"
#include "frontends/p4/inlining.h"
#include "frontends/p4/removeReturns.h"
#include "frontends/p4/moveConstructors.h"
#include "midend/actionSynthesis.h"
#include "frontends/p4/localizeActions.h"
#include "frontends/p4/removeParameters.h"
#include "midend/local_copyprop.h"
#include "midend/simplifyKey.h"
#include "midend/simplifySelectCases.h"
#include "midend/simplifySelectList.h"
#include "midend/validateProperties.h"
#include "midend/compileTimeOps.h"
#include "midend/predication.h"
#include "midend/expandLookahead.h"
#include "midend/tableHit.h"
#include "frontends/p4/simplifyParsers.h"
#include "frontends/p4/typeMap.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "frontends/common/resolveReferences/resolveReferences.h"
#include "frontends/p4/toP4/toP4.h"
#include "frontends/p4/simplify.h"
#include "frontends/p4/unusedDeclarations.h"
#include "frontends/p4/moveDeclarations.h"
#include "frontends/common/constantFolding.h"
#include "frontends/p4/strengthReduction.h"
#include "frontends/p4/uniqueNames.h"
#include "midend/actionSynthesis.h"
#include "midend/convertEnums.h"
#include "midend/copyStructures.h"
#include "midend/eliminateTuples.h"
#include "midend/local_copyprop.h"
#include "midend/nestedStructs.h"
#include "midend/removeLeftSlices.h"
#include "midend/simplifyKey.h"
#include "midend/simplifySelectCases.h"
#include "midend/simplifySelectList.h"
#include "midend/validateProperties.h"
#include "midend/compileTimeOps.h"
#include "midend/predication.h"
#include "midend/expandLookahead.h"
#include "midend/tableHit.h"
#include "midend/midEndLast.h"

namespace FPGA {

const IR::ToplevelBlock* MidEnd::run(const IR::P4Program* program, const FPGAOptions& options) {
    if (program == nullptr)
        return nullptr;

    bool isv1 = options.langVersion == CompilerOptions::FrontendVersion::P4_14;
    refMap.setIsV1(isv1);
    auto evaluator = new P4::EvaluatorPass(&refMap, &typeMap);

    PassManager midEnd = {
        new P4::RemoveReturns(),
        new P4::MoveConstructors(),
        new P4::RemoveAllUnusedDeclarations(RemoveUnusedPolicy()),
        new P4::ClearTypeMap(&typeMap),
        evaluator,
        new P4::Inline(&typeMap, RemoveUnusedPolicy(), false, evaluator),
        new P4::InlineActions(&typeMap, RemoveUnusedPolicy()),
        new P4::LocalizeAllActions(RemoveUnusedPolicy()),
        new P4::UniqueNames(),
        new P4::UniqueParameters(&typeMap),
        new P4::SimplifyControlFlow(&typeMap, true),
        new P4::RemoveActionParameters(&typeMap),
        new P4::SimplifyKey(&typeMap, new P4::OrPolicy(new P4::IsValid(&typeMap), new P4::IsMask())),
        new P4::ConstantFolding(&typeMap),
        new P4::StrengthReduction(&typeMap),
        new P4::SimplifySelectCases(&typeMap, true),  // require constant keysets
        new P4::ExpandLookahead(&typeMap),
        new P4::SimplifyParsers(),
        new P4::StrengthReduction(&typeMap),
        new P4::EliminateTuples(&typeMap),
        new P4::CopyStructures(&typeMap),
        new P4::NestedStructs(&typeMap),
        new P4::SimplifySelectList(&typeMap),
        new P4::Predication(),
        new P4::ConstantFolding(&typeMap),
        new P4::LocalCopyPropagation(&typeMap),
        new P4::ConstantFolding(&typeMap),
        new P4::MoveDeclarations(),  // more may have been introduced
        new P4::SimplifyControlFlow(&typeMap, true),
        new P4::CompileTimeOperations(),
        new P4::TableHit(&typeMap),
        new P4::MoveActionsToTables(&refMap, &typeMap),
        new P4::TypeChecking(&refMap, &typeMap),
        new P4::SimplifyControlFlow(&typeMap, true),
        new P4::RemoveLeftSlices(&typeMap),
        new P4::TypeChecking(&refMap, &typeMap),
        new P4::ConstantFolding(&typeMap, false),
        new P4::TypeChecking(&refMap, &typeMap),
        new P4::SimplifyControlFlow(&typeMap, true),
        new P4::RemoveAllUnusedDeclarations(RemoveUnusedPolicy()),
        evaluator,
        new VisitFunctor([this, evaluator](){ toplevel = evaluator->getToplevelBlock(); }),
    };
    midEnd.setName("MidEnd");
    midEnd.addDebugHooks(hooks);
    program = program->apply(midEnd);
    if (errorCount() > 0)
        return nullptr;

    return toplevel;
}

}  // namespace FPGA
