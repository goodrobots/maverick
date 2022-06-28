#!/usr/bin/env python3
# This fact extracts as much hardware information out of a Tegra board as possible

import os, re, sys, subprocess

class Tegra(object):
    def __init__(self):
        self.data = {'present': 'no'}
        
    def boarddata(self):
        count = 0
        
        try:
            if os.path.isdir("/sys/module/tegra_fuse/parameters"):
                self.data['vendor'] = 'Nvidia'
                self.data['present'] = 'yes'
            else:
                self.data['vendor'] = None
        except:
            pass
        
        try:
            with open('/sys/module/tegra_fuse/parameters/tegra_chip_id', 'r') as f:
                board = f.readline().strip()
                if board == "64":
                    self.data['model'] = 'TK1'
                elif board == "33": # TK1 and Nano share the same tegra_chip_id 
                    self.data['model'] = 'TX1'
                elif board == "25": # AGX and Xavier NX share the same tegra_chip_id 
                    self.data['model'] = 'AGX'
                elif board == "24":
                    self.data['model'] = 'TX2'
                else:
                    self.data['model'] = None
        except:
            pass
        
        try:
            with open('/proc/device-tree/model', 'r') as f:
                board = f.readline().strip()
                if re.search('nano', board, re.IGNORECASE):
                    self.data['model'] = 'Jetson Nano'
                elif re.search('xavier nx', board, re.IGNORECASE):
                    self.data['model'] = 'Jetson Xavier NX'
        except:
            pass
        
        # Define main data container
        f = open('/proc/cpuinfo', 'r')
        for line in f:
            r = re.search('^(.*)\s+:\s+(.*)', line)
            if not r or not r.groups(0) or not r.groups(0)[0] or not r.groups(0)[1]: continue
            (key,val) = r.groups(0)[0],r.groups(0)[1]
            if key == "processor":
                count += 1
        self.data['cpucores'] = count
        f.close()
        f = open('/proc/meminfo', 'r')
        for line in f:
            r = re.search('^(.*):\s+(.*)', line)
            if not r or not r.groups(0) or not r.groups(0)[0] or not r.groups(0)[1]: continue
            (key,val) = r.groups(0)[0],r.groups(0)[1]
            if key == "MemTotal": 
                self.data['memory'] = val
            elif key == "SwapTotal":
                self.data['swap'] = val
        f.close()

    def storagedata(self):
        # Obtain the SD card size from proc
        f = open('/proc/partitions', 'r')
        for line in f:
            if re.search("mmcblk[01]$", line):
                self.data['sdsize'] = int(line.split()[2]) / 1000
        f.close()
        
    def runall(self):
        self.boarddata()
        self.storagedata()

#If we're being called as a command, instantiate and report
if __name__ == '__main__':
    tegra = Tegra()
    tegra.boarddata()
    if tegra.data['present'] == "no":
        print("tegra_present=no")
        sys.exit(1)
    tegra.storagedata()

    # Finally, print the data out in the format expected of a fact provider
    if tegra.data:
        for key,val in tegra.data.items():
            print("tegra_%s=%s" % (key, val))
