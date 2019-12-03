#!/bin/bash
FECHA_Y_HORA=`date "+%Y%m%d-%H%M%S"`
NOMBRE_ARCHIVO="backup_$FECHA_Y_HORA.tgz"
CARPETA_DESTINO="/var/backups/Folder"
CARPETA_RESPALDAR="/usr/share/nginx/html/NameApp"
mkdir -p "$CARPETA_DESTINO"
tar cfvz "$CARPETA_DESTINO/$NOMBRE_ARCHIVO" "$CARPETA_RESPALDAR"