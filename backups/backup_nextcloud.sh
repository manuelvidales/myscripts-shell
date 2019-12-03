#!/bin/bash

############################################################################

#!/bin/sh

DATE=`date +%Y%m%d%H%M%S`
DEST_DIR='/var/backups/appsall/nextcloud'          # Carpeta destino backup
SOURCE_DIRS='/usr/share/nginx/html/nextcloud'      # Carpeta origen backup
NXT_BACKUP_STRING=nextcloud-dir-$DATE              # Nombre backup directorio
BD_BACKUP_STRING=nextcloud-sql-$DATE.sql           # Nombre backup BD
ERROR=0                                            # Control de errores

USER=user                                          # usuario de BD
PASS=123                                           # pass de la BD
DATABASE=nextcloud                                 # Nombre de la BD

BACKUPS_TO_KEEP=7                                  # Numero de Backups a conservar
EXCLUSSIONS=""					                   # ficheros a excluir del backup
OPTIONS="-Aax --progress"                          # -n para hacer simular rsync

############################################################################
# Busqueda de los backups anteriores                                       #
############################################################################

BACKUPS=`ls -t $DEST_DIR |grep backup-`
BACKUP_COUNTER=0
BACKUPS_LIST=()

for x in $BACKUPS
do
    BACKUPS_LIST[$BACKUP_COUNTER]="$x"
    echo "[" `date +%Y-%m-%d_%R` "]" "backups detectados:" ${BACKUPS_LIST[$BACKUP_COUNTER]}
    let BACKUP_COUNTER=BACKUP_COUNTER+1

done

############################################################################
# Borrar los backups mas antiguos, Respetando los dias a conservar         #
############################################################################

if [ $BACKUPS_TO_KEEP -lt ${#BACKUPS_LIST[*]} ]; then
  let BACKUPS_TO_DELETE=${#BACKUPS_LIST[*]}-$BACKUPS_TO_KEEP
  echo "[" `date +%Y-%m-%d_%R` "]" "Necesario borrar" $BACKUPS_TO_DELETE" backups" $BACKUPS_TO_DELETE

  while [ $BACKUPS_TO_DELETE -gt 0 ]; do
    BACKUP=${BACKUPS_LIST[${#BACKUPS_LIST[*]}-1]}
    unset BACKUPS_LIST[${#BACKUPS_LIST[*]}-1]
    echo "[" `date +%Y-%m-%d_%R` "]" "Backup a borrar:" $BACKUP
    sudo rm -rf $DEST_DIR"/"$BACKUP
    if [ $? -ne 0 ]; then
      echo "[" `date +%Y-%m-%d_%R` "]" "####### Error borrando el backup #######"
    else
      echo "[" `date +%Y-%m-%d_%R` "]" "Backup correctamente eliminado"
    fi
    let BACKUPS_TO_DELETE=BACKUPS_TO_DELETE-1
  done
else
  echo "[" `date +%Y-%m-%d_%R` "]" "No es necesario borrar backups"
fi

##########################################################################################
# 	Activamos el modo mantenimiento para descartar usuarios usando el sistema            #
##########################################################################################

sudo -u nginx php /usr/share/nginx/html/nextcloud/occ maintenance:mode --on
echo "[" `date +%Y-%m-%d_%R` "]" "== Modo Mantenimiento Activado ==" >> $DEST_DIR/success.log
echo "[" `date +%Y-%m-%d_%R` "]" "== Modo Mantenimiento Activado =="

##########################################################################################
#  Backup del directorio Nextcloud y grabar el log del proceso                           #
##########################################################################################

sudo rsync $OPTIONS $EXCLUSSIONS $SOURCE_DIRS $DEST_DIR/$NXT_BACKUP_STRING 2>> $DEST_DIR/error.log

if [ $? -ne 0 ]; then
    echo "####### Error rsync  #######"$'\r' >> $DEST_DIR/error.log
    echo -e "rsync fallo el $(date +'%d-%m-%Y %H:%M:%S')"$'\r' >> $DEST_DIR/error.log
    echo "[" `date +%Y-%m-%d_%R` "]" "####### Error rsync  #######"
    ERROR=1
else
    echo  "[" `date +%Y-%m-%d_%R` "]" "Backup carpeta Nextcloud se realizo correctamente" >> $DEST_DIR/nextcloud-backup.log
    echo  "[" `date +%Y-%m-%d_%R` "]" "Backup carpeta Nextcloud se realizo correctamente"
fi


##########################################################################################
# Backup de la BD  de Nextcloud y grabando en un log el proceso                          #
##########################################################################################

sudo mysqldump --single-transaction -h localhost --user=$USER --password=$PASS $DATABASE > $DEST_DIR/$BD_BACKUP_STRING 2>> $DEST_DIR/error.log

if [ $? -ne 0 ]; then
    echo -e "mysqldump fallo el $(date +'%d-%m-%Y %H:%M:%S')"$'\r' >> $DEST_DIR/error.log
    echo "[" `date +%Y-%m-%d_%R` "]" "####### Error mysqldump  #######"
    echo "####### Error mysqldump  #######"$'\r' >> $DEST_DIR/error.log
    ERROR=1
else
    echo  "[" `date +%Y-%m-%d_%R` "]" "Backup BD realizado correctamente" >> $DEST_DIR/success.log
    echo  "[" `date +%Y-%m-%d_%R` "]" "Backup BD realizado correctamente"
fi

##########################################################################################
# Si no hay Error, Uno, Comprimo y Borro los Backups                                   #
##########################################################################################

if [ $ERROR -eq 0 ]; then
    sudo tar -cvzf $DEST_DIR/backup-nextcloud-$DATE.tar.gz  $DEST_DIR/nextcloud*$DATE 2>> $DEST_DIR/error.log
    if [ $? -ne 0 ]; then
        echo "####### Error rsync  #######"$'\r' >> $DEST_DIR/error.log
        echo -e "tar -cvzf fallo el $(date +'%d-%m-%Y %H:%M:%S')"$'\r' >> $DEST_DIR/error.log
        echo "[" `date +%Y-%m-%d_%R` "]" "####### Error en la ejecucion de tar  #######"
    else
        echo  "[" `date +%Y-%m-%d_%R` "]" "tar -cvzf realizado correctamente" >> $DEST_DIR/success.log
        echo  "[" `date +%Y-%m-%d_%R` "]" "tar -cvzf realizado correctamente"
        sudo rm -fr $DEST_DIR/$BD_BACKUP_STRING
        sudo rm -fr $DEST_DIR/$NXT_BACKUP_STRING
        echo "[" `date +%Y-%m-%d_%R` "]" "Backup Finzalido con exito!!!" >> $DEST_DIR/success.log
        echo "[" `date +%Y-%m-%d_%R` "]" "Backup Finzalido con exito!!!"
    fi
fi

##########################################################################################
#       Desactivamos el modo mantenimiento para volverlo a dejar disponible              #
##########################################################################################

sudo -u nginx php /usr/share/nginx/html/nextcloud/occ maintenance:mode --off
echo "[" `date +%Y-%m-%d_%R` "]" "== Modo Mantenimiento DESActivado	==" >> $DEST_DIR/success.log
echo "[" `date +%Y-%m-%d_%R` "]" "== Modo Mantenimiento DESActivado =="
##########################################################################################

