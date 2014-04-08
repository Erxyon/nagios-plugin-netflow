#!/bin/bash
FICHIER=$(readlink -f $0)
DIR=$(dirname ${FICHIER})
echo $DIR

DIR_INSTALL=/netflow

# Creation de l'utilisateur netflow
useradd netflow
echo -e "netflow\nnetflow" | passwd netflow

# Creation des repertoires + Permissions
# 
mkdir ${DIR_INSTALL}
chown netflow:apache ${DIR_INSTALL}
chmod 777 ${DIR_INSTALL}

mkdir ${DIR_INSTALL}/run
chown netflow:apache ${DIR_INSTALL}/run
chmod 777 ${DIR_INSTALL}/run

mkdir ${DIR_INSTALL}/data
chown netflow:apache ${DIR_INSTALL}/data


# Installation de rrdtool et nfdump

yum install zlib-devel cairo-devel libxml2-devel pango-devel pango libpng-devel freetype freetype-devel libart_lgpl-devel gcc g++ libtool gdb gdbm-devel libpcap-devel libpcap gcc-c++ flex byacc
tar -xvzf $DIR/rrdtool-1.4.5.tar.gz -C ${DIR_INSTALL}
export PKG_CONFIG_PATH=/usr/lib/pkgconfig/
cd ${DIR_INSTALL}/rrdtool-1.4.5
./configure
make
make install
cd ${DIR_INSTALL}

tar -xvzf $DIR/nfdump-1.6.5.tar.gz -C ${DIR_INSTALL}
cd ${DIR_INSTALL}/nfdump-1.6.5
./configure --prefix=/ --enable-nfprofile --with-rrdpath=/opt/rrdtool-1.4.5/
make
make install
cd ${DIR_INSTALL}

cd ${DIR}
cp ${DIR}/plugin.sh ${DIR_INSTALL}/plugin.sh
cp ${DIR}/stats.sh ${DIR_INSTALL}/stats.sh

