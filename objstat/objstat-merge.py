#!/usr/bin/env python3

"""Merge the columns of two objstat files by object and place into one file.

"""

import argparse
import csv
import sys

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("files", nargs=2, metavar="<file>",
                    help="Files to compare")
parser.add_argument("-o", dest="out_file", metavar="<file>",
                    help="Output filename", default="-")
args = parser.parse_args()

obj = {}

file_fh = open(args.files[0], "rU")
dialect_one = csv.Sniffer().sniff(file_fh.read(1024))
file_fh.seek(0)
reader = csv.reader(file_fh, dialect_one)
count = 0
headers_one = None
obj_header = None
place_header = None
for r in reader:
    if count == 0:
        obj_header = r[0]
        place_header = r[1]
        headers_one = r[2:]
    else:
        obj_name = r[0]
        obj_place = r[1]
        if obj_name not in obj:
            obj[obj_name] = {}
        if obj_place not in obj[obj_name]:
            obj[obj_name][obj_place] = {}
        for i, h in enumerate(headers_one):
            obj[obj_name][obj_place][h + "1"] = r[i + 2]
    count += 1
file_fh.close()

file_fh = open(args.files[1], "rU")
dialect_two = csv.Sniffer().sniff(file_fh.read(1024))
file_fh.seek(0)
reader = csv.reader(file_fh, dialect_two)
count = 0
headers_two = None
for r in reader:
    if count == 0:
        headers_two = r[2:]
    else:
        obj_name = r[0]
        obj_place = r[1]
        if obj_name not in obj:
            obj[obj_name] = {}
        if obj_place not in obj[obj_name]:
            obj[obj_name][obj_place] = {}
        for i, h in enumerate(headers_two):
            obj[obj_name][obj_place][h + "2"] = r[i + 2]
    count += 1
file_fh.close()

for o in obj:
    for p in obj[o]:
        for h in headers_one:
            header = h + "1"
            if header not in obj[o][p]:
                obj[o][p][header] = ""
        for h in headers_two:
            header = h + "2"
            if header not in obj[o][p]:
                obj[o][p][header] = ""

# Put the headers in a reasonable order, with the pairs adjacent when
# possible.
out_headers = [obj_header, place_header]
for h in headers_one:
    out_headers.append(h + "1")
    if h in headers_two:
        out_headers.append(h + "2")
for h in headers_two:
    header = h + "2"
    if header not in out_headers:
        out_headers.append(header)

if args.out_file == "-":
    out_fh = sys.stdout
else:
    out_fh = open(args.out_file, "w")
writer = csv.DictWriter(out_fh, out_headers, dialect=dialect_one)
writer.writeheader()
for o in sorted(obj.keys()):
    for p in sorted(obj[o].keys()):
        row = {obj_header : o, place_header : p}
        for k in obj[o][p]:
            row[k] = obj[o][p][k]
        writer.writerow(row)
out_fh.close()
