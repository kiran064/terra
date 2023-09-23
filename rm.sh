#!/bin/bash
echo "enter name of file which you want to remove= n\"
read File
filerm=$(locate $File | head -1)
rm -rf $filerm