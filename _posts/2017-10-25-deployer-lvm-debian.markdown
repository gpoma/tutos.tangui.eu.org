---
title: Déployer lvm sur une debian fraichement installée (par exemple pour une dédibox)
date:  2017-10-25 17:30
layout: post
---

En root

Installation de lvm et rsync :

    aptitude install lvm2 rsync

Réperer la localisation nom de la partition data :

    df -h

Ici on a :

    /dev/sda2                     900G  0   900G   0% /data

Démontage et suppression de la partition /data :

    umount /data
    rm -rf /data

Création du volume physique sur la partition qui contenait /data :

    pvcreate /dev/sda2

Création du groupe lvm

    vgcreate volgroup /dev/sda2

Pour vérifier que tout a été bien créé

    vgdisplay

Création des partitions lvm logique

    lvcreate -L 50G -n varlib /dev/volgroup
    lvcreate -L 20G -n home /dev/volgroup

Formatage des partitions en ext4

    mkfs.ext4 /dev/volgroup/varlib
    mkfs.ext4 /dev/volgroup/home

Montage des partitions du lvm dans home pour les synchroniser avec les dossiers actuels

    mkdir /tmp/home
    mkdir /tmp/varlib

    mount /dev/volgroup/home /tmp/home/
    mount /dev/volgroup/varlib /tmp/varlib/

Synchronisation du contenu des dossiers dans les partitions lvm

    rsync -a /home/ /tmp/home/
    rsync -a /var/lib/ /tmp/varlib/

Ajouter les partitions lvm dans le fichier /etc/fstab pour le montage automatique

    /dev/volgroup/varlib                      /var/lib        ext4    defaults        0       2
    /dev/volgroup/home                        /home           ext4    defaults        0       2

Ne pas oublier d'enlever le montage automatique du /etc/fstab de la partition sur /data

Monter les partitions à partir du fstab

    mount -a

Pour vérifier que tout est ok

    mount
    df -h
    ls -l /home
    ls -l /var/lib

Démontage des montages dans /tmp

    umount /tmp/home
    umount /tmp/varlib

Rédemarrer la machine pour l'ultime contrôle

    reboot

Monter la partition root qui accueillait à l'origine la home et varlib

    mkdir /tmp/root
    mount /dev/sda1 /tmp/root/

Supprimer le contenu des dosssiers home et varlib de la partition root

    rm -rf /tmp/root/home/*
    rm -rf /tmp/root/var/lib/*

Démontage du root temporaire

    umount /tmp/root
