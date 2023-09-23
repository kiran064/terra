#!/bin/bash
a=42
if [$a%2 -eq 0]
then
    echo "no is even"
else
    echo "no is odd"
fi