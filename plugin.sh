#!/bin/bash

######################
# UTILISATION
######################

# plugin.sh 1.1.1.1 all
# plugin.sh 1.1.1.1 filtre tcp 5001

if [ $# -eq 0 ]; then
	echo "Usage : plugin.sh IP all"
	echo "Usage : plugin.sh IP filtre PROTOCOLE PORT"
	exit 0
fi

######################
# PARAMETRES
######################

# PARAMETRES GENERAUX
BASEDIR=/netflow
NFCAPD=/bin/nfcapd
USER=netflow
GROUP=apache
TEMPFILE="/netflow/temp_cmd.txt"
PORT=2055

# PARAMETRES PAR FLUX
IP=${1:-"10.0.0.2"}
TYPE=${2:-"all"}
FILTRE_PROTO=${3:-"tcp"}
FILTRE_PORT=${4:-5001}

IDENTIFIANT=$IP
REPDATA=$BASEDIR/data/$IDENTIFIANT

#######################
# LANCEMENT NFDUMP
#######################

# 1) Creation du repertoire si n'existe pas
if [ ! -d $REPDATA ]; then
mkdir $REPDATA
chown netflow:apache $REPDATA
chmod 777 $REPDATA
fi

# 2) Lancement de nfcapd si pas lance

NB=`ps aux | grep "[0-9][[:space:]]$NFCAPD -w -D -p $PORT -u $USER -g $GROUP -t 60 -B 200000 -S 1 -P $BASEDIR/run/p$PORT.pid -z -l $REPDATA" | wc -l`
NB2=`ps aux | grep "[0-9][[:space:]]$NFCAPD" | wc -l`

if [ $NB -lt 1 ]; then
echo "nfcapd relance"
if [ $NB2 -gt 0 ]; then
killall nfcapd
fi

`$NFCAPD -w -D -p $PORT -u $USER -g $GROUP -t 60 -B 200000 -S 1 -P $BASEDIR/run/p$PORT.pid -z -l $REPDATA`

fi


# -w : change de fichier toutes les 5 minutes
# -D : s'execute en arriere-plan
# -p <port> : port d'ecoute
# -u <user> -g <groupe> : indique les proprietaires des fichiers crees
# -B <taille> : taille du buffer

# -z : Compresse les fichiers crees

# -S : format des sous-repertoires
# -l (petit L) : repertoire contenant les fichiers crees
# -I (grand I) : identifiant 

# 3) Recherche du dernier fichier nfcapd
FICHIER=`find ${REPDATA} -name "*nfcapd.2*" -ls | sort -k11r | head -n 1 | awk '{print \$11}'`

if [ -z $FICHIER ]; then
	echo "Aucune donnee - Attendre 1 minute"
	exit 3; #TODO verif warning
fi
echo $FICHIER

# 4) Recuperation des donnees netflow
# Custom format
# protocole portDestination bits/s
if [ "$TYPE" = "all" ]; then
	#RESULT=`nfdump -N -r $FICHIER -q -s dstport:p/bps -n 10 | sed 's/([^)]*)//g' | awk '{print \$4" "\$5" "\$10}'`
	RESULT=`nfdump -N -r $FICHIER -q -o fmt:%pr%dp\ %bps -a -A proto`
else
	echo "proto $FILTRE_PROTO and dst port $FILTRE_PORT" > $TEMPFILE
	RESULT=`nfdump -N -r $FICHIER -q -o fmt:%pr%dp\ %bps -a -A proto,dstport -f $TEMPFILE`
fi


# 5) Parcours des donnees
DONNEES=""
i=0
OCTETS=""
TITRE=""

for ligne in $RESULT
do
	
	# On recupere le protocole
	if [ $i -eq 0 ]; then
		if [ $ligne -eq 6 ]; then
			TITRE="TCP"
		elif [ $ligne -eq 17 ]; then
			TITRE="UDP"
		elif [ $ligne -eq 1 ]; then
			TITRE="ICMP"
		else
			TITRE=$ligne
		fi
		i=1


	# On recupere le port
	elif [ $i -eq 1 ]; then
		if [ "$TYPE" = "all" ]; then
			i=2
		else
			TITRE=$TITRE" $ligne"
			i=2
		fi

	# On recupere le nombre d'octets
	elif [ $i -eq 2 ]; then
		OCTETS=$ligne
		i=0
		DONNEES=${DONNEES}"'$TITRE'=${OCTETS}B ";
		TITRE=""
		OCTETS=""
	fi
done

if [ -z "${DONNEES}" ]; then
	if [ "$TYPE" = "all" ]; then
		echo "Aucune donnee"
	else
		echo "Aucune donnee | '$FILTRE_PROTO $FILTRE_PORT'=0B"
	fi
else
	echo "OK | $DONNEES"
fi
exit 0;


