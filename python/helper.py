import re

def get_camel_case(column_name):
    return re.sub('_([a-z])', lambda match: match.group(1).upper(), column_name)

def convert(name):
    s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
    return re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1).lower()

def camelCase(st):
    output = ''.join(x for x in st.title() if x.isalnum())
    return output[0].lower() + output[1:]

def CamelCase(st):
    output = ''.join(x for x in st.title() if x.isalnum())
    return output

def toState(st):
    return "State"+CamelCase(st)

