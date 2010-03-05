#!/bin/sh

source /usr/local/thrift/venv/bin/activate
STRESS=python /root/stress.py

$STRESS --operation insert \
  --num-keys=2000000 \
  --nodes=${peers} \
  --file=/root/insert.txt

$STRESS --operation read \
  --num-keys=2000000 \
  --nodes=${peers} \
  --file=/root/read.txt
