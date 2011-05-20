#!/usr/bin/env python
# coding=utf-8

# $Id$
# $HeadURL$ 

# list.py -- gives a quick overview of the contents of a Solr schema.xml

import sys

try:
    from lxml import etree
except ImportError:
    try:
        import xml.etree.cElementTree as etree
    except ImportError:
        print("Unable to import etree from any known place")

def index_fields(filename):
    doc = etree.parse(filename)
    fields = doc.findall("fields/field")
    rv = []
    for fld in fields:
        field = {}
        for att in fld.attrib.keys():
            field[att] = fld.attrib.get(att)
        rv.append(field)
    return rv

def encode_field(fld):
    ov = u""
    idx = fld.get("indexed", "false") == "true"
    stor = fld.get("stored", "false") == "true"
    req = fld.get("required", "false") == "true"
    multi = fld.get("multiValued", "false") == "true"
    card = u"?"
    if multi:
        if not req:
            card = u"*"
        else:
            card = u"+"
    else:
        if req:
            card = u"✓" 

    ov += fld['name'] + u"[%s]\n" % ( card )
    ov += u"\t%(type)s\n" % fld
    if "default" in fld:
        ov += u"\tdefault: “%s”\n" % fld['default']
    if idx or stor:
        sv = u""
        if idx:
            sv += u"indexed"
            if stor:
                sv += u", "
        if stor:
            sv += u"stored"
        
        ov += u"\t%s\n" % sv
    return ov
    
if __name__ == '__main__':
    schema = len(sys.argv) > 1 and sys.argv[1] or "schema.xml"
    for fld in index_fields(schema):
        line = encode_field(fld)
        print(line.encode("utf-8"))
    
    



