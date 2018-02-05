#!/bin/sh
for file in sd???.dat; do
    if [ ! -f $file.org ]; then
        mv $file $file.org
        echo $file
        ./fix_sd $file.org > $file
        if [ $? != 0 ]; then
            echo "Something went wrong in fixing $file"
            mv $file.org $file
            exit
        fi
    fi
done
