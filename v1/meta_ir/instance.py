#!/usr/bin/env python

"""
@file
@brief MetaIR configuration declaration

Does syntax validation of an MetaIR configuration instance.
"""

import os
import yaml
from collections import OrderedDict # Requires Python 2.7

from common import *

class FileAggregator(object):
    """
    Aggregate a bunch of files into a single string of input.
    Track offsets for each file
    """
    def __init__(self, files=None):
        self.aggregate = ""
        self.offsets = OrderedDict()
        self.total_lines = 0
        if files is not None:
            self.add_file(files)

    def add_file(self, files):
        """
        @brief Add file or files to the aggregator
        @param files A filename or list of filenames to add
        """
        if isinstance(files, list):
            for filename in files:
                self._add_file(filename)
        else:
            self._add_file(files)

    def _add_file(self, filename):
        logging.debug("Adding file %s to aggregate" % filename)
        with open(filename) as f:
            self.offsets[filename] = self.total_lines
            self.aggregate += f.read()
            self.total_lines = len(self.aggregate.split("\n")) - 1

    def absolute_to_file_offset(self, offset):
        """
        @brief Return the (filename, file-offset) for the given offset
        @param offset An absolute offset in self.aggregate
        """

        meta_ir_assert(offset <= self.total_lines, "Bad offset reference")
        prev_filename = None
        prev_file_offset = -1
        for filename, file_offset in self.offsets.items():
            if offset < file_offset:
                break # Found the "next" file
            prev_filename = filename
            prev_file_offset = file_offset
        return (prev_filename, offset - prev_file_offset)

    def file_to_absolute_offset(self, filename, file_offset):
        """
        @brief Return the absolute offset for the given file and file_offset
        @param filename The name of the file
        @param file_offset The relative location in filename
        @returns The absolute offset of the line in the aggregate

        Does no error checking
        """
        return self.offsets[filename] + file_offset

# These are the metalanguage names recognized by MetaIR
meta_ir_keys = ["meta_ir_types", "meta_ir_attributes", "meta_ir_processors"]

class MetaIRInstance(object):
    """
    @brief An MetaIR configuration object definition

    @param meta_ir_types Recognized MetaIR types
    @param meta_ir_attrs Recognized MetaIR attributes by MetaIR type
    @param meta_ir_processor_types List of types that are to be recognized 
    as processors
    @param meta_ir_object_map Map from top level MetaIR objects to attribute maps
    @param external_object_map Map from non-MetaIR objects to attribute maps

    Build the Python maps directly derived from the YAML structures.

    An meta_ir_instance object has an attribute for each entry in meta_ir_types
    which is a map from names to objects of that type; for instance
    header, table, metadata...

    meta_ir_instance.header[hdr_name]
    meta_ir_instance.parser[parser_name]
    etc
    """

    def __init__(self, meta_ir_yaml):
        """
        @brief Init the meta_ir_instance object
        @param meta_ir_yaml The top level definitions (type, attrs) to use

        meta_ir_yaml is loaded by yaml.load; so it may be YAML text or
        a file object containing YAML text.

        If meta_ir_yaml is not specified, try to open the local file meta.yml.

        """
        self.meta_ir_types = []
        self.meta_ir_processor_types = []
        self.meta_ir_attrs = {}
        self.meta_ir_object_map = {}
        self.external_object_map = {}
        self.aggregate_list = [] # List of aggregator objects

        with open(meta_ir_yaml, 'r') as fin:
            try:
                self.process_yaml(yaml.load(fin))
            except MetaIRValidationError, e:
                msg = "Could not process top level yaml: " + str(e.args)
                meta_ir_fatal_error(msg)
        
    def process_meta(self, key, val):
        """
        @brief Process an MetaIR metalanguage directive
        @param key The top level key
        @param val The value associated with the key

        Supported metalanguage directives are listed in meta_ir_keys
        """
        if key == "meta_ir_types":
            self.meta_ir_types.extend(val)
            # Initialize attributes for type with basics
            for type in val:
                if not type in self.meta_ir_attrs.keys():
                    self.meta_ir_attrs[type] = ["type", "doc"]
                    # Add a map for objects of this type to the config
                    setattr(self, type, {})
        elif key == "meta_ir_attributes":
            for type, attrs in val.items():
                if type not in self.meta_ir_types:
                    raise MetaIRValidationError(
                        "Attrs assigned to unknown type: " + type)
                self.meta_ir_attrs[type].extend(attrs)
        elif key == "meta_ir_processors":
            self.meta_ir_processor_types.extend(val)

    def process_meta_ir_object(self, name, attrs):
        """
        @brief Process an MetaIR object declaration
        @param name The name of the object
        @param attrs The value associated with the object
        """
        # For now, just validate
        type = attrs["type"]
        # Check that attrs are all recognized
        for attr, attr_val in attrs.items():
            if attr not in self.meta_ir_attrs[type]:
                if True: # To be command line option "strict"
                    raise MetaIRValidationError(
                        "Object '" + name + "' had bad attr: " + attr)
                else:
                    logging.warn("Object '" + name + "' had bad attr: " + attr)

        # Check that required attrs are present; TBD until "required" known
        # for attr in self.meta_ir_attrs[type]:
        #     if attr not in attrs.keys():
        #         raise AIRValidationError(
        #             "Object '" + name + "' is missing attr: " + attr)

        # Check if present in top level already
        if name in self.meta_ir_object_map.keys():
            # For now, this is an error; may need per-type way to handle
                raise MetaIRValidationError(
                    "MetaIR object '" + name + "' redefined")
        self.meta_ir_object_map[name] = attrs

        # Add this to the object set
        type_objs = getattr(self, type)
        type_objs[name] = attrs
        logging.debug("Added object %s of type %s", name, type)

    def process_external_object(self, name, attrs):
        """
        @brief Process an object not recognized as an MetaIR object
        @param name The name of the object
        @param attrs The value associated with the object

        External objects are just recorded for classes that inherit from MetaIR
        """
        self.external_object_map[name] = attrs
        logging.debug("Added external object %s", name)

    def process_yaml(self, input):
        """
        @brief Add YAML content to the MetaIR instance
        @param input The YAML dict to process
        @returns Boolean, False if error detected
        """

        for key, val in input.items():
            if key in meta_ir_keys:
                self.process_meta(key, val)
            elif isinstance(val, dict) and "type" in val.keys():
                self.process_meta_ir_object(key, val)
            else:
                self.process_external_object(key, val)

    def add_content(self, input):
        """
        @brief Add content to this MetaIR instance
        @param input a file object, name of a file to read or list of filenames
        @returns Boolean: False if error detected in content

        If a list of files is given, they are aggregated into one
        chunk of input and processed by yaml as a whole.
        """
        logging.debug("Adding content %s" % str(input))

        if isinstance(input, file):
            input_string = input.read()
        else:
            agg = FileAggregator(input)
            input_string = agg.aggregate
            self.aggregate_list.append(agg)

        yaml_input = yaml.load(input_string)
        logging.debug("Yaml loaded for %s" % str(input))

        try:
            self.process_yaml(yaml_input)
        except MetaIRValidationError, e:
            meta_ir_fatal_error("Could not process input files %s: %s" %
                            (str(input), str(e.args)))

# Current test just instantiates an instance
if __name__ == "__main__":
    import sys
    local_dir = os.path.dirname(os.path.abspath(__file__))
    meta_yaml = os.path.join(local_dir, "tests", "sample_meta.yml")
    instance = MetaIRInstance(meta_yaml)
    if len(sys.argv) > 1:
        instance.add_content(sys.argv[1])

    meta_ir_assert(isinstance(instance.header, dict), "No headers attribute")
    meta_ir_assert("ethernet" in instance.header.keys(),
               "Expected ethernet in header map")
