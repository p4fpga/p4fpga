import astbsv as ast
from utils import GetHeaderWidthInState

# Generate ParseState Object from parseGraph
class ParseState(object):
    REGULAR = "REGULAR"
    EMPTY = "EMPTY"
    def __init__(self, id, name):
        self.id = id
        self.name = name
        self.len = GetHeaderWidthInState(name)
        self.state_type = ParseState.REGULAR
        self.transitions = None
        self.transition_keys = None
        self.parse_ops = None

    def __repr__(self):
        return "ParseState: %s %s %s" % (self.id, self.name, self.len)

def apply_pdict (tmpls, pdict):
    stmt = []
    for t in tmpls:
        stmt.append(ast.Template(t, pdict))
    return stmt

def apply_action_block(stmt):
    """
        wrap list of stmt in an action block
        @param: list of stmt
        @rtype: ActionBlock in a []
    """
    return [ast.ActionBlock(stmt)]

def apply_if_verbosity(verbosity, stmt):
    assert type(stmt) is list
    assert type(verbosity) is int
    return [ast.If("cr_verbosity[0] > %d"%(verbosity), stmt)]

def apply_case_stmt(caseExpr, stmt):
    stmt = ast.Case('v')
    return [ast.Case(case_expr)]
