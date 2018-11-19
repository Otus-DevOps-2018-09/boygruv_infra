#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import json
import sys
import subprocess

def main():

    a = {
        'all':
        { 'hosts':
                get_vm_ip()
        }
    }

    print a

def get_vm_ip():
    cmd = 'gcloud compute instances list --format="csv(networkInterfaces[0].accessConfigs[0].natIP)[no-heading]"'
    PIPE = subprocess.PIPE
    p = subprocess.Popen(cmd, shell=True, stdin=PIPE, stdout=PIPE, 
        stderr=subprocess.STDOUT, close_fds=True, cwd='/home/')

    vm_line = []

    for vm in p.stdout:
        vm_line.append(vm.rstrip())

    return vm_line


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--list":
        main()
    else:
        print("Usage: getvm.py --list")

