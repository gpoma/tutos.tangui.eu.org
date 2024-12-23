---
title: Diviser la partition root en raid en plusieurs partitions
date:  2022-05-06 09:30
layout: post
---

Pour réaliser cette procédure, on a besoin de modifier la partition root. Il faut donc booter en mode rescue (ou via un live cd).

## Identifier le raid de la partition root

Liste les périphérique raid :

    $ cat /proc/mdstat
Personalities : [raid1] [linear] [multipath] [raid0] [raid6] [raid5] [raid4] [raid10] 
    md126 : active (auto-read-only) raid1 sda3[1] sdb3[0]
          975055872 blocks super 1.2 [2/2] [UU]
          	resync=PENDING
          bitmap: 7/8 pages [28KB], 65536KB chunk

    md127 : active (auto-read-only) raid1 sda2[1] sdb2[0]
          523264 blocks super 1.2 [2/2] [UU]

Et repérage des détails de chacun d'entre eux :
  
    $ tune2fs -l /dev/md126
    tune2fs 1.45.5 (07-Jan-2020)
    Filesystem volume name:   <none>
    Last mounted on:          /
    Filesystem UUID:          3b617f47-b28d-4c8f-9f17-697779d503bc
    Block count:              243763968
    Reserved block count:     12188198
    Overhead blocks:          4108002
    Free blocks:              239277665
    Free inodes:              60907081
    [...]

Le point de montage est bien /, c'est donc notre périphérique.

## Réduction de la taille du raid

Vérification du système de fichier :

    $ e2fsck -f /dev/md126
    
Réduction de la taille :

    $ resize2fs /dev/md126 40G

Réduction de la taille du raid :

    $ mdadm --grow --size 45G /dev/md126
    mdadm: component size of /dev/md126 has been set to 52428800K

On prend volontairement des taille plus petite que la taille visée de 50G histoire d'éviter les problèmes de conversion d'unités

## Retaille la première partition

Il faut retailler une à une les partitions de chacun des disques.

    $ mdadm --manage --set-faulty /dev/md126 /dev/sda3

    $ mdadm --manage --remove /dev/md126 /dev/sda3

Désactiver les autres partitions (via `mdadm --stop` et/ou `swapoff`) puis retailler le disque pour réduire la partition sda3 à 50G.

    $ fdisk /dev/sda

    $ partprobe /dev/sda

Une fois réalisé, on peut reconstituer le raid :

    $ mdadm --add /dev/md126 /dev/sda3

Il faut ensuite attendre que les données soient recopiées (`cat /proc/mdadm`).

## Copier la taille pour la seconde partitions

Désactiver l'usage de toutes les partitions du 2d disque en commençant par celle faisant partie du raid :

    $ mdadm --manage --set-faulty /dev/md126 /dev/sdb3

    $ mdadm --manage --remove /dev/md126 /dev/sdb3


Puis copier la table des partition du premier sur le 2d disque :

    $ sfdisk -d /dev/sda   | sfdisk /dev/sdb

On prévient le noyau du changement de partitions :

    $ partprobe /dev/sdb

On ajoute le 2d disque dans le raid :

    $ mdadm --add /dev/md126 /dev/sdb3

## Mise d'ecquerre des tailles :

    $ mdadm --grow --size 49G /dev/md126

    $ resize2fs /dev/md126
    resize2fs 1.45.5 (07-Jan-2020)
    Filesystem at /dev/md126 is mounted on /root/root; on-line resizing required
    old_desc_blocks = 6, new_desc_blocks = 7
    The filesystem on /dev/md126 is now 13107200 (4k) blocks long.

