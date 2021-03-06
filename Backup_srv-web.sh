#!/bin/bash

## Script de sauvegarde du serveur web WordPress sous Linux Debian 10 sur serveur ftp ####

### Pré-recquis : installation de lftp pour l'envoi des sauveagardes au serveur ftp ###
# Installation de lftp
# apt install lftp

### Information du serveur stp ###
hostname=srv-ftp
ftp_srv=192.168.56.108
user_ftp=ftpuser
pass_ftp=pass

### Rotation des sauvegardes (2 jours) ###
d=2
rotation=$(date +%d-%m-%Y --date "$d days ago")

### Date du jour ###
date="$(date +%d-%m-%Y)"

### Emplacement des logs ###
log="/home/manager/log_sauvegarde/log-$date"

##########################################
### Sauvegarde du répertoire WordPress ###
##########################################
# Définition des variables
source1="/var/www/html/wordpress"
name='basename $source'
dest="/home/manager/sauvegarde" # Répertoire de sauvegarde local

# Création du répertoire de sauvegarde local
mkdir -p $dest

echo " Répertoire à sauvegarder : $source1 "

# Copie du répertoire WordPress
echo " Copie du répertoire : $name, dans le répertoire sauvegarde local "
cp -r $source1 $dest/$name-$date

## Status de la copie du répertoire WordPress
status=$?
case $status in 
	0) echo "Copie du répertoire wordpress effectuée" >> $log;;
	1) echo "Erreur : copie du répertoire wordpress non effectuée" >> $log && exit;;
esac

## Autre Possibilité ##
# Création de l'archive
# tar czvf $dest/$name-$date.tar.gz $dest

# Envoi de l'archive sur le serveur ftp
# echo " Envoi des fichier sur $hostname "
# lftp ftp://$user_ftp:$pass_ftp@$ftp_srv -e "mirror -e -R $dest /home/ftpuser/ftp_dir/wordpress/$date;quit"

# Rotation des sauvegardes
# lftp ftp://$user_ftp:$pass_ftp@$ftp_srv -e "rm -rf $rotation;quit"

# Suppression du répertoire de sauvegarde local
# rm -fr $dest
# echo " Sauvegarde répertoire WordPress terminée "

#########################################
### Sauvegarde bases de données MySQL ###
#########################################
# Définition des variables
mysql_user=root
name_mysql="mysql"

# Sauvegarde de la base de donnée wordpress
echo " Sauvegarde de la base de donnée : wordpress "
mysqldump --user=$mysql_user --databases wordpress > $dest/$name_mysql-$date.sql

## Status de la copie de la base de donnée WordPress
status=$?
case $status in 
	0) echo "Copie de la base de donnée wordpress effectuée" >> $log;;
	1) echo "Erreur : copie de la base de donnée wordpress non effectuée" >> $log && exit;;
esac

## Autre Possibilité ##
# Envoi de l'archive sur le serveur ftp
# echo " Envoi des fichiers sur $hostname "
# lftp ftp://$user_ftp:$pass_ftp@$ftp_srv -e "mirror -e -R $dest_mysql /home/ftpuser/ftp_dir/mysql/$date;quit"

# Rotation des sauvegardes
# lftp ftp://$user_ftp:$pass_ftp@$ftp_srv -e "rm -rf $rotation;quit"

# Suppression du répertoire de sauvegarde local
# rm -fr $dest_mysql
# echo " Sauvegarde répertoire WordPress terminée "

########################################################################
### Sauvegarde des fichiers de configuration de Apache, MySQL et PHP ###
########################################################################
# Définition des variables
source2="/etc/apache2"
source3="/etc/mysql"
source4="/etc/php"
name_conf_apache="apacheconf"
name_conf_mysql="mysqlconf" 
name_conf_php="phpconf"
				#####################
echo " Copie des fichiers de configuration Apache2 "
cp -r $source2 $dest/$name_conf_apache-$date
				######################
echo " Copie des fichiers de configuration MySQL "
cp -r $source3 $dest/$name_conf_mysql-$date
				######################
echo " Copie des fichiers de configuration PHP "
cp -r $source4 $dest/$name_conf_php-$date

## Status de la copie des fichiers de configuration
status=$?
case $status in 
	0) echo "Copie des fichiers de configuration effectuées" >> $log;;
	1) echo "Erreur : copie des fichiers de configurations non effectuée" >> $log && exit;;
esac

#############################################
### Envoi des archives sur le serveur ftp ###
#############################################
# Définition des variables
name_backup="sauvegarde_srvWeb"

# Création de l'archive de sauvegarde complète
echo " Création de l'archive : $name_backup-$date "
tar -czvf $dest/$name_backup-$date.tar.gz $dest/
# Suppression des fichiers inclus dans l'archive de sauvegarde
rm -rf $dest/$name_conf_apache-$date
rm -rf $dest/$name_conf_mysql-$date
rm -rf $dest/$name_conf_php-$date
rm -rf $dest/$name_mysql-$date.sql
rm -rf $dest/$name-$date

# Envoi de l'archive sur le serveur ftp
echo " Envoi des fichiers sur $name_backup-$date.tar.gz " 
lftp ftp://$user_ftp:$pass_ftp@$ftp_srv -e "mirror -R $dest/ /home/ftpuser/ftp_dir/sauvegarde/$date;quit"

## Status de la création et transfert de l'archive
status=$?
case $status in 
	0) echo "Création et transfert de l'archive effectuée" >> $log;;
	1) echo "Erreur : création et transfert de l'archive non effectuée" >> $log && exit;;
esac

# Rotation des sauvegardes
lftp ftp://$user_ftp:$pass_ftp@$ftp_srv -e "rm -rf /home/ftpuser/ftp_dir/sauvegarde/$rotation;quit"

## Status de la rotation
status=$?
case $status in 
	0) echo "Rotation effectuée" >> $log;;
	1) echo "Erreur : rotation non effectuée" >> $log && exit;;
esac

# Suppression du répertoire de sauvegarde local
rm -fr $dest
echo " Sauvegarde du serveur Web terminé " > $log