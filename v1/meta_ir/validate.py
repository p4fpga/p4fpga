"""
@file
@brief Validator for MetaIR

Does semantic validation of the MetaIR instance
"""

from common import *

def meta_ir_validate_parser(instance):
    """
    @brief Semantic validation of an MetaIR instance
    @param instance The MetaIR instance map
    @returns Boolean, True if instance is valid.

    The instance is assumed to be a syntactically valid instance.
    This routine checks:

        The Parser:
            Each edge connects two declared states

    In so doing, the validator generates additional structures
    and binds them to the IR. These inc
    """
    pass

def meta_ir_validate_instance(instance):
    """
    @brief Semantic validation of an MetaIR instance
    @param instance The MetaIR instance map
    @returns Boolean, True if instance is valid.

    The instance is assumed to be a syntactically valid instance.
    This routine calls the object specific validators:
        parser
        tables

        The Parser:
            Each edge connects two declared states

    In so doing, the validator generates additional structures
    and binds them to the IR. These inc
    """
    pass


def meta_ir_check_object(meta_ir_instance, obj_type_name, name, type, 
                     implementation_type=None):
    """
    @brief Check basic MetaIR characteristics for an object reference
    @param meta_ir_instance The top level mapping for the IR
    @param obj_type_name The name of the object to report on error
    @param name The name of the top level object
    @param type The expected MetaIR type for the object
    @param implementation_type If not None, check impl is present and has type

    TODO Support a set for implementation type
    """

    meta_ir_assert(name in meta_ir_instance.keys(),
               "%s: %s is not in top level for type %s" % 
               (obj_type_name, name, type))
    meta_ir_assert("type" in meta_ir_instance[name].keys(), 
               "%s: %s is not an MetaIR object" % (obj_type_name, name))
    meta_ir_assert(meta_ir_instance[name]["type"] == type,
               "%s: %s is not the expected type. Got %s, expected %s" %
               (obj_type_name, name, meta_ir_instance[name]["type"], type))

    if implementation_type is not None:
        meta_ir_assert("format" in meta_ir_instance[name].keys(), 
                   "%s: Expected format indication for %s" %
                   (obj_type_name, name))
        meta_ir_assert(meta_ir_instance[name]["format"] == implementation_type,
                   "%s: implementation format for %s is %s, expected %s" %
                   (obj_type_name, name, meta_ir_instance[name]["format"],
                    implementation_type))
        meta_ir_assert("implementation" in meta_ir_instance[name].keys(), 
                   "%s: Expected implemenation for %s" %
                   (obj_type_name, name))
        meta_ir_assert("implementation" in meta_ir_instance[name].keys(), 
                   "%s: Expected implemenation for %s" %
                   (obj_type_name, name))

def meta_ir_check_header(meta_ir_instance, name):
    """
    @brief Validate a reference to an MetaIR header
    @param meta_ir_instance The top level MetaIR instance map
    @param name The name of the header
    @returns Boolean, True if a valid reference
    """
    if name not in meta_ir_instance.keys():
        return False
    if "type" not in meta_ir_instance[name].keys():
        return False
    if meta_ir_instance[name]["type"] != "header":
        return False
    return True

def meta_ir_validate_data_ref(meta_ir_instance, name):
    """
    @brief Validate a reference to an MetaIR field
    @param meta_ir_instance The top level MetaIR instance map
    @param name The reference being checked
    @returns Boolean, True if a valid reference

    Currently only supports header and header.fld
    """
        
    parts = name.split(".")
    if len(parts) == 1:
        return meta_ir_check_header(meta_ir_instance, parts[0])
    elif len(parts) == 2:
        return meta_ir_find_field(meta_ir_instance, parts[0], parts[1]) is not None
    return False

