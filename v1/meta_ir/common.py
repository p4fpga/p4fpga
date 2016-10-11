#!/usr/bin/env python
"""
Common includes for MetaIR

@TODO Put exceptions in own file and work out reasonable
namespacing conventions for this module.
"""

# Common code for the IRI implementation

import logging
from exception import *

# These are the match types supported
meta_ir_valid_match_types = ["valid", "exact", "ternary", "lpm"]

def meta_ir_fatal_error(msg):
    logging.critical(msg)
    exit(1)

def meta_ir_find_field(meta_ir_instance, header_name, field_name):
    """
    @brief Find the field type given the header and field name
    @param meta_ir_instance The top level MetaIR instance map
    @param header_name The header name
    @param field_name The field name
    @returns A field type object if found, else None
    """
    if not meta_ir_check_header(meta_ir_instance, header_name):
        return False
    for entry in meta_ir_instance[header_name]["fields"]:
        if isinstance(entry, dict) and field_name in entry.keys():
            return entry[field_name]


def meta_ir_assert(cond, msg="", exception=MetaIRValidationError):
    """
    Check an assertion
    @param cond The assertion condition
    @param msg The message to report if condition fails
    @param exception The exception to raise

    This is intended for fatal errors
    """
    if not cond:
        raise exception("ASSERT failed: " + msg)

def meta_ir_check(cond, exception):
    """
    Check a run time condition and raise an exception if it fails

    @param cond The assertion condition
    @param exception The exception to raise

    This is intended for exceptions that are expected to
    be handled in the code.
    """
    if not cond:
        raise exception

# This is from https://gist.github.com/jaredks/6276032
# This is the simple version. See the above link for a thread
# safe version as well.

from collections import OrderedDict as _OrderedDict
 
class ListDict(_OrderedDict):
    def __insertion(self, link_prev, key_value):
        key, value = key_value
        if link_prev[2] != key:
            if key in self:
                del self[key]
            link_next = link_prev[1]
            self._OrderedDict__map[key] = link_prev[1] = link_next[0] = [link_prev, link_next, key]
        dict.__setitem__(self, key, value)
 
    def insert_after(self, existing_key, key_value):
        self.__insertion(self._OrderedDict__map[existing_key], key_value)
 
    def insert_before(self, existing_key, key_value):
        self.__insertion(self._OrderedDict__map[existing_key][0], key_value)


def deref_or_none(dictionary, key):
    """
    @brief Look up a key in a dict; return None if not found
    """
    if not dictionary:
        return None

    if key in dictionary.keys():
        return dictionary[key]
    else:
        return None

def deref_or_zero(dictionary, key):
    """
    @brief Look up a key in a dict; return None if not found
    """
    if not dictionary:
        return 0

    if key in dictionary.keys():
        return dictionary[key]
    else:
        return 0

# Test cases
if __name__ == "__main__":
    x = ListDict()
    x["a"] = "A"
    x["b"] = "B"
    x.insert_after("a", ("x", "X"))
    x.insert_before("b", ("y", "Y"))

