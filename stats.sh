#!/bin/bash

##################
# PARAMETRES
##################

if [ $# -eq 0 ]; then
	echo "Usage : stats.sh <IP> [Nb]"
	exit 0
fi

IP=${1:-"1.1.1.1"}
NB=${2:-"10"}

REPDATA=/netflow/data/$IP

FICHIER=`find ${REPDATA} -name "*nfcapd.2*" -ls | sort -k11r | head -n 1 | awk '{print \$11}'`

nfdump -r $FICHIER -s dstport:p/bps -n $NB

