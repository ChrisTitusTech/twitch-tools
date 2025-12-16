#!/bin/bash
NAME="Titus"
if [[ "$#" == 0 ]]
then
    termdown -f roman -T "Be  Right      Back" 5 && termdown -f roman -T "$NAME is LATE !"
elif ! [ $1 -eq $1 ] 2>/dev/null
then
    echo $1 is not an INTEGER to use as minutes
else
    termdown -f roman -T "Be  Right      Back" $(expr $1 \* 60) && termdown -f roman -T "$NAME is LATE !"
fi
