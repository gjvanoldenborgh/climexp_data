#!/bin/sh
./get_monthly.py
./get_daily.py
$HOME/NINO/copyfiles.sh era20c_*_??.nc