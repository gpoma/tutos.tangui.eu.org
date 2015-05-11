---
title: Créer un VPN avec tinc
date:  2015-05-11 18:54
layout: post
---

[Tinc](http://tinc-vpn.org/) est un logiciel libre très partique pour créer un VPN simplement. Il a de plus la qualité d'être bien maintenu par Debian.

##Installation du logiciel

Pour l'installer, vous pouvez le faire depuis Ubuntu ou Debian avec la commande suivante :

    user@serveur:~$ sudo apt-get install tinc

##Création d'un noeud serveur

Si Tinc est un VPN décentralisé, certains noeuds doivent être présents pour accueillir les connexions des autres noeuds. Nous allons donc créer ce noeud.

Tinc est conçu pour héberger plusieurs réseaux. La première étape est donc de créer un répertoire pour notre réseau que nous appellerons *mon_reseau*.

    user@serveur:~$ sudo mkdir /etc/tinc/mon_reseau

###Création du fichier tinc.conf

La configuration principale du serveur pour *mon_reseau* sera stoquée dans le fichier */etc/tinc/mon_reseau/tinc.conf*. Créez le avec le contenu suivant :

    #Interface réseau
    Device=/dev/net/tun
    #Port d'écoute permettant aux autres noeuds de se connecter
    Port=655
    #Le VPN fonctionnera en mode switch 
    #(pas besoin de définir de route mais les packets ne sont pas diffusés à tous les noeuds)
    Mode=switch
    #Identifiant de la machine sur le VPN
    Name=mon_serveur
    #Clé privée de la machine sur le réseau VPN
    PrivateKeyFile=/etc/tinc/mon_reseau/rsa_key.priv

NB: La signification des directives est indiquée en commentaire avant leur utilisation

###Création des clés et du fichier host

Le fichier de configuration faire référence à une clé privée via la directive *PrivateKeyFile*. Voici la commande qui permet de la générer :

    user@serveur:~$ sudo tincd -n mon_reseau -K

NB: il s'agit d'un K majuscule, le k minuscule a un autre sens, nous y reviendrons.

Vous pouvez valider les valeurs par défaut proposées, ce sont les chemins des fichiers contenant la clé privée et la clé publique :

    Generating 2048 bits keys:
    .......................................................................+++ p
    ...............................+++ q
    Done.
    Please enter a file to save private RSA key to [/etc/tinc/mon_reseau/rsa_key.priv]: 
    Please enter a file to save public RSA key to [/etc/tinc/mon_reseau/hosts/mon_serveur]: 

A la suite de cette procédure, nous avons donc deux nouveau fichiers :

- */etc/tinc/mon_reseau/rsa_key.priv* : le fichier de la clé privée (il doit être lisible par le seul administrateur de la machine)
- */etc/tinc/mon_reseau/hosts/mon_serveur* : le fichier contenant la clé publique

###Ajout des informations liés au *host*

Le fichier contenant la clé publique a vocation à être présent sur tous les noeuds qui souhaitent se connecter au serveur. Nous allons donc y ajouter les informations nécessaires permettant ces connexion. Voici ce qu'il devrait contenir :

    #Activation de la compression
    Compression=9
    Address=MON_ADRESSE_PUBLIQUE 655
    -----BEGIN RSA PUBLIC KEY-----
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    -----END RSA PUBLIC KEY-----

NB: N'oubliez pas de changer **MON_ADRESSE_PUBLIQUE** par l'adresse IP du serveur.

###Configuration de la couche réseau

Dernière étapage, il faut attribuer une adresse IP privée à notre noeud serveur (son adresse au sein du VPN). Pour se faire, on utilise un script shell qui est lancé par Tinc à la fin de son initialisation. Ce script doit d'appeler *tinc-up*. Nous créons donc un ficheir dans */etc/tinc/mon_reseau/tinc-up* qui contient les éléments suivants :

    #!/bin/bash
    
    iptables $INTERFACE 10.0.0.1 netmask 255.255.255.0

NB: Changez 10.0.0.1 et le mask réseau à votre convenance ;)

Comme ce fichier est un script shell qui sera executé par tinc, il faut lui donner les droits d'execution :

    user@serveur:~$ sudo chown u+rx /etc/tinc/mon_reseau/tinc-up

###Lancement de tinc pour notre réseau

C'est bon nous sommes prets : nous avons une configuration du serveur, déclaré un *host* qui a une clé publique et une clé privée et un script de démarrage du réseau. Nous pouvons donc lancer tinc grace à la commande suivante :

    user@serveur:~$ sudo tincd -n mon_reseau

NB: si vous avez choisi un autre nom de réseau que *mon_reseau* utilisez le ;-)

Maintenant, nous avons une nouvelle interface réseau :

    user@serveur:~$ sudo ifconfig 
    mon_reseau  Link encap:Ethernet  HWaddr XX:XX:XX:XX:XX:XX  
                inet addr:10.1.1.1  Bcast:10.1.1.255  Mask:255.255.255.0
                UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1

    eth0        Link encap:Ethernet  HWaddr XX:XX:XX:XX:XX:XX  
                inet addr:MON_ADRESSE_PUBLIQUE  Bcast:XXX.XXX.XXX.255  Mask:255.255.255.0
                UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1

    lo          Link encap:Local Loopback  
                inet addr:127.0.0.1  Mask:255.0.0.0
                inet6 addr: ::1/128 Scope:Host

###S'assurer que le serveur peut être contacter

Pour recevoir les demandes de connexion des noeuds "clients", il faut s'assurer que le serveur peut être contacté sur le port choisi en TCP et UDP (par défaut et dans notre exemple 655). Si ce n'est pas le cas, et que votre parefeux est iptables, voici les commandes permettant d'y parvenir :

     user@serveur:~$ sudo iptables -I INPUT -p tcp --dport 655 -j ACCEPT
     user@serveur:~$ sudo iptables -I INPUT -p udp --dport 655 -j ACCEPT

##Configuration du noeud client

Pour que tinc fonctionne sur un noeud client, il doit installé :

     user@client:~$ sudo apt-get install tinc

Et un répertoire pour le réseau VPN mon_reseau doit être créé :

     user@client:~$ sudo mkdir /etc/tinc/mon_reseau

###Création d'un fichier de configuration

Comme pour le serveur, un fichier de configuration *tinc.conf* doit être créé dans le répertoire dédié à la configuration de *mon_reseau*. Le fichier */etc/tinc/mon_reseau/tinc.conf* ressemblera beaucoup au fichier du serveur :

    #Interface réseau
    Device=/dev/net/tun
    #Le VPN fonctionnera en mode switch
    #(pas besoin de définir de route mais les packets ne sont pas diffusés à tous les noeuds)
    Mode=switch
    #Identifiant de la machine sur le VPN
    Name=mon_premier_client
    #Clé privée de la machine sur le réseau VPN
    PrivateKeyFile=/etc/tinc/mon_reseau/rsa_key.priv

NB: L'identification de mon noeud client ici sera mon_premier_client. N'hésitez pas à le changer.

Seul la directive *Port* n'est pas obligatoire.

###Génération d'un fichier host et d'une clé privée

Pour générer la paire de clé qui permettra au serveur de nous reconnaitre, il faut utiliser la même commande que pour le serveur :

    user@serveur:~$ sudo tincd -n mon_reseau -K

On a à l'issue de cette procédure, deux nouveaux fichiers */etc/tinc/mon_reseau/rsa_key.priv* et */etc/tinc/mon_reseau/hosts/mon_premier_client*

###Création du fichier de configuration réseau

Comme pour le serveur, il faut créer un script d'initialisation de notre nouvelle interface réseau */etc/tinc/mon_reseau/tinc-up* :

    #!/bin/bash

    iptables $INTERFACE 10.0.0.2 netmask 255.255.255.0

NB: L'IP VPN du client sera ici *10.0.0.2*. Choisissez la en accord avec celle choisie pour le serveur.

###Autentification du serveur et du client

L'autentification des différents noeuds se font par le mécanisme de clé privée et de clé publique. Il faut donc déposer les fichiers hosts du serveur et du client dans leur répertoire *hosts* respectif. Vous pouvez soit les transférer par *scp* ou *rsync*, soit en copier/coller le contenu.

A l'issue de cette procédure; vous devrez donc avoir sur le serveur :

    user@serveur:~$ cat /etc/tinc/mon_reseau/hosts/mon_premier_client
    -----BEGIN RSA PUBLIC KEY-----
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    -----END RSA PUBLIC KEY-----
    user@serveur:~$ cat /etc/tinc/mon_reseau/hosts/mon_serveur
    #Activation de la compression
    Compression=9
    Address=MON_ADRESSE_PUBLIQUE 655
    -----BEGIN RSA PUBLIC KEY-----
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    -----END RSA PUBLIC KEY-----


Et sur le client, la même chose :

    user@client:~$ cat /etc/tinc/mon_reseau/hosts/mon_premier_client
    -----BEGIN RSA PUBLIC KEY-----
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    -----END RSA PUBLIC KEY-----
    user@client:~$ cat /etc/tinc/mon_reseau/hosts/mon_serveur
    #Activation de la compression
    Compression=9
    Address=MON_ADRESSE_PUBLIQUE 655
    -----BEGIN RSA PUBLIC KEY-----
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    -----END RSA PUBLIC KEY-----

###Lancer tinc sur le client

Nos deux machines sont maintenant configurées et sont capables de se reconnaitre grâce à leurs fichiers *hosts*. Nous pouvons donc lancer tinc sur le noeud client :

    user@client:~$ tincd -n mon_reseau

Nous devrions maintenant être capable de pinger le client depuis le serveur :

    user@serveur:~$ ping 10.0.0.2
    PING 10.0.0.2 (10.0.0.2) 56(84) bytes of data.
    64 bytes from 10.0.0.2: icmp_seq=1 ttl=64 time=0.051 ms

Et inversement :

    user@client:~$ ping 10.0.0.1
    PING 10.0.0.2 (10.0.0.1) 56(84) bytes of data.
    64 bytes from 10.0.0.1: icmp_seq=1 ttl=64 time=0.051 ms

##Arreter tinc

Pour arrêté le démon tinc sur l'un des noeuds :

    user@client:~$ sudo tincd -n mon_reseau -k

NB: il s'agit ici d'un k miniscule ;-)

##Enregistrer un réseau tinc au démarrage

Pour activer l'un des réseau tinc au démarrage d'un des noeuds, il faut l'ajouter dans le fichier */etc/tinc/nets.boot* :

     ## This file contains all names of the networks to be started on system startup.
     mon_reseau

##Débugger tinc

Si tinc ne fonctionne, vous pouvez le lancer en mode non démon :

    user@client:~$ tincd -n mon_reseau -d3 -D

Pour l'arreter, mettez la tache en sommeil grace à *CRTL* + *Z*, executer la commande d'arrêt de tinc :

    user@client:~$ tincd -n mon_reseau -k

Puis réveillez la tache tinc :

    user@client:~$ fg

Des logs sont également produit dans */var/log/deamon.log* pour les version récente de Debian. (Sinon */var/log/syslog*).

*Merci à taziden qui m'a fait récouvrir tinc !*
