"""
MetaIR exception definitions
"""

class MetaIRValidationError(Exception):
    """
    Error validating some MetaIR representation
    """
    pass


class MetaIRRefError(Exception):
    """
    Error referencing some MetaIR object
    """
    pass
