#include "foptions.h"
#include "ir/ir.h"
#include "midend.h"
#include "midend/actionsInlining.h"
#include "midend/inlining.h"
#include "midend/removeReturns.h"
#include "midend/moveConstructors.h"
#include "midend/actionSynthesis.h"
#include "midend/localizeActions.h"
#include "midend/removeParameters.h"
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
#include "midend/actionsInlining.h"
#include "midend/actionSynthesis.h"
#include "midend/convertEnums.h"
#include "midend/copyStructures.h"
#include "midend/eliminateTuples.h"
#include "midend/local_copyprop.h"
#include "midend/localizeActions.h"
#include "midend/moveConstructors.h"
#include "midend/nestedStructs.h"
#include "midend/removeLeftSlices.h"
#include "midend/removeParameters.h"
#include "midend/removeReturns.h"
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

const IR::P4Program* MidEnd::run(const FPGAOptions& options, const IR::P4Program* program) {
    if (program == nullptr)
        return nullptr;

    bool isv1 = options.langVersion == CompilerOptions::FrontendVersion::P4_14;
    refMap.setIsV1(isv1);
    auto evaluator = new P4::EvaluatorPass(&refMap, &typeMap);

    PassManager simplify = {
        new P4::RemoveReturns(&refMap),
        new P4::MoveConstructors(&refMap),
        new P4::RemoveAllUnusedDeclarations(&refMap),
        new P4::ClearTypeMap(&typeMap),
        evaluator,
    };

    simplify.setName("Simplify");
    simplify.addDebugHooks(hooks);
    program = program->apply(simplify);
    if (::errorCount() > 0)
        return nullptr;
    auto toplevel = evaluator->getToplevelBlock();
    if (toplevel->getMain() == nullptr)
        // nothing further to do
        return nullptr;

    P4::InlineWorkList toInline;
    P4::ActionsInlineList actionsToInline;

    PassManager midEnd = {
        new P4::Inline(&refMap, &typeMap, evaluator),
        new P4::InlineActions(&refMap, &typeMap),
        new P4::LocalizeAllActions(&refMap),
        new P4::UniqueNames(&refMap),
        new P4::UniqueParameters(&refMap, &typeMap),
        new P4::SimplifyControlFlow(&refMap, &typeMap),
        new P4::RemoveActionParameters(&refMap, &typeMap),
        new P4::SimplifyKey(&refMap, &typeMap,
                            new P4::NonLeftValue(&refMap, &typeMap)),
        new P4::ConstantFolding(&refMap, &typeMap),
        new P4::StrengthReduction(),
        new P4::SimplifySelectCases(&refMap, &typeMap, true),  // require constant keysets
        new P4::ExpandLookahead(&refMap, &typeMap),
        new P4::SimplifyParsers(&refMap),
        new P4::StrengthReduction(),
        new P4::EliminateTuples(&refMap, &typeMap),
        new P4::CopyStructures(&refMap, &typeMap),
        new P4::NestedStructs(&refMap, &typeMap),
        new P4::SimplifySelectList(&refMap, &typeMap),
        new P4::Predication(&refMap),
        new P4::ConstantFolding(&refMap, &typeMap),
        new P4::LocalCopyPropagation(&refMap, &typeMap),
        new P4::ConstantFolding(&refMap, &typeMap),
        new P4::MoveDeclarations(),  // more may have been introduced
        new P4::SimplifyControlFlow(&refMap, &typeMap),
        new P4::CompileTimeOperations(),
        new P4::TableHit(&refMap, &typeMap),
        new P4::MoveActionsToTables(&refMap, &typeMap),
        new P4::TypeChecking(&refMap, &typeMap),
        new P4::SimplifyControlFlow(&refMap, &typeMap),
        new P4::RemoveLeftSlices(&refMap, &typeMap),
        new P4::TypeChecking(&refMap, &typeMap),
        new P4::ConstantFolding(&refMap, &typeMap, false),
        new P4::TypeChecking(&refMap, &typeMap),
        new P4::SimplifyControlFlow(&refMap, &typeMap),
        new P4::RemoveAllUnusedDeclarations(&refMap),
        // evaluator,
    };
    midEnd.setName("MidEnd");
    midEnd.addDebugHooks(hooks);
    program = program->apply(midEnd);
    if (::errorCount() > 0)
        return nullptr;

    return program;
}

}  // namespace FPGA
