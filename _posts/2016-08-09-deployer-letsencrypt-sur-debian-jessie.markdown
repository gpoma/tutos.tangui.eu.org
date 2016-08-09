---
title: Deployer letsencrypt sous Debian Jessie
date:  2016-08-09 14:00
layout: post
---

[Let's Encrypt](https://letsencrypt.org/) est projet qui permet de déployer des certificats https sans avoir recours à des autorités de certification payante. L'appel à un webservice du projet letsencrypt permet de vérifier l'authenticité de la demande et de certifier les clés liés à un nom de domaine.

Ce projet s'interconnecte donc avec le serveur HTTP sur lequel vous souhaiter déployer les certificats HTTPS afin de répondre positivement à ce dialogue d'authentification.

Les certificats seront renouvelés automatiquement via une cron.

## Installer de dépot jessie-backport

Les packets Debian ne sont pas disponibles de base pour Jessie mais Debian met à disposition ce packet via le dépot *jessie-backport*. Pour activer ce dépot, vous pouvez créer un fichier source.list pour apt dans le répertoire ``/etc/apt/sources.list.d/`` ayant comme nom par exemple ``backports.list`` avec le contenu :

    deb http://ftp.us.debian.org/debian/ jessie-backports main

Une fois ajouté, il faut mettre à jour apt avec la commande ``sudo aptitude update`` pour que le dépot soit intégrer dans votre instance apt.

## Installer les packets letsencrypt

Pour installer letsencrypt ainsi que les outils de dialogue avec le webservice de certification et le renouvellement automatique, vous pouvez installer le packet ``letsencrypt.sh-apache2`` (si vous utilisez apache2 comme serveur http/https) :

    user@host:~ $ sudo aptitude install letsencrypt.sh-apache2

Ce packet va installer ``letsencrypt.sh`` (les scripts shell permettant la création et le renouvellement autormatique) en plus des éléments nécessaires à l'authentification des domaines via apache.

## S'assurer de la bonne configuration d'apache

Assurez vous que votre configuration https fonctionne correctement et notamment que les modules apache ``ssl`` et que le site https par défaut (``default-ssl.conf``) soient activés :

    user@host:~ $ sudo a2enmod ssl 
    Considering dependency setenvif for ssl:
    Module setenvif already enabled
    Considering dependency mime for ssl:
    Module mime already enabled
    Considering dependency socache_shmcb for ssl:
    Module socache_shmcb already enabled
    Module ssl already enabled
    host@host:~$ sudo a2ensite default-ssl.conf 
    Site default-ssl already enabled

De même assurez-vous que le ou les domaines que vous comptez utiliser en https pointe bien sur votre machine. Si votre machine a comme adresse ip *10.10.10.10* et que vos domaines sont *example.org* et *www.example.org*, vous devirez avoir :

    user@host: host example.org
    example.org has address 10.10.10.10
    user@host: host www.example.org
    example.org has address 10.10.10.10

Du coup, ces domaines devraient répondre correctement aux requêtes https :

    user@host: curl -sk https://example.org/ | head
    
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <title>Apache2 Debian Default Page: It works</title>
        <style type="text/css" media="screen">
          * {
        margin: 0px 0px 0px 0px;
        padding: 0px 0px 0px 0px;
     
    user@host: curl -sk https://www.example.org/ | head

    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <title>Apache2 Debian Default Page: It works</title>
        <style type="text/css" media="screen">
          * {
        margin: 0px 0px 0px 0px;
        padding: 0px 0px 0px 0px;

De plus, vérifiez que la configuration liée au dialogue d'authentification a bien été pris en compte pour vos domaines :

    user@host: $ curl -s http://example.org/.well-known/acme-challenge/
    <!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
    <html><head>
    <title>403 Forbidden</title>
    </head><body>
    <h1>Forbidden</h1>
    <p>You don't have permission to access /.well-known/acme-challenge/ on this server.<br /></p>
    <hr>
    <address>Apache/2.4.10 (Debian) Server on example.org Port 80</address>
    </body></html>

L'erreur ``403`` est normale. En revanche si vous avez une ``404`` c'est que la configuration apache voulue par *letsencrypt.sh-apache2* n'est pas prise en compte. Peut être avez vous une directive *RewriteRule* qui bypasse la configuration de ``/etc/apache2/conf-enabled/letsencrypt.sh.conf``.

Vérifiez bien que tous les domaines sur lesquels vous cherchez à utiliser https réponde par une 403.

## Configuration de letsencrypt.sh

La configuration se letsencrypt.sh se passe en deux temps :

 - la définition des domaines
 - la configuration du processus d'automatisation letsencrypt.sh

### Définition des domaines à utiliser

Pour chaque certificat ssl dédié à https, vous allez devoir créer une ligne dans le fichier ``/var/lib/letsencrypt.sh/domains.txt``. Si un même applicatif http peut être servit depuis plusieurs domaines, vous pouvez créer un certificat pour tous les domaines concernés. Vous aurez donc une ligne par VirtualHost apache2 pour le port *:443 (et donc par ``ServerName`` concerné) et vous inscrirez les ``ServerAlias`` comme domaines secondaires.

Si vous souhaitez créer un certificat pour *example.org* (le ``ServerName`` de votre ``VirtualHost *:443``) lié à un domaine secondaire *www.example.org* (le ``ServerAlias`` lié à *example.org*), votre fichier ``/var/lib/letsencrypt.sh/domains.txt`` contiendra donc la ligne suivante :

    example.org www.example.org

### Configuration du processus d'automatisation

Deux fichiers sont à créer pour gérer l'automatisation des créations et renouvellements des processus :
 - un fichier de configuration général
 - un fichier permettant de redémarrer les services impactés

Le fichier de configuration général se trouve dans le répertoire ``/etc/letsencrypt.sh/conf.d/`` vous pouvez lui donner le nom qui vous convient (pour notre exemple, nous l'appelons ``example.sh``. Il doit contenir la référence à la licence d'utilisation du webservice letsencrypt (variable shell ``LICENSE``), l'adresse email de contact (variable ``CONTACT_EMAIL``) et la référence au script de redémarrage des service (variable ``HOOK``) :

    user@host:~ $ cat /etc/letsencrypt.sh/conf.d/example.sh
    HOOK='/etc/letsencrypt.sh/hook.sh'
    CONTACT_EMAIL=contact@example.org
    LICENSE="https://letsencrypt.org/documents/LE-SA-v1.1.1-August-1-2016.pdf"

Attention, en production, *letsencrypt* **limite le nombre de requêtes** possibles par domaine à quelques dixaines par jour. Si vous souhaitez utiliser *letsencrypt* en mode bac à sable plutot que directement en interrogeant le webservice de production, vous pouvez ajouter la ligne suivante :

    CA="https://acme-staging.api.letsencrypt.org/directory"

Une fois que vos tests effectués, vous pourrez supprimer cette ligne (ainsi que les fichiers ``/var/lib/letsencrypt.sh/private_key.json``, ``/var/lib/letsencrypt.sh/private_key.pem`` et tous ceux qui se trouvent dans les sous répertoires de ``/var/lib/letsencrypt.sh/certs/``).

Pour le script de redémarrage des services, (que nous avons nommé ``/etc/letsencrypt.sh/hook.sh`` dans le fichier de configuration), il permet de redémarrer apache une fois les nouvelles clés déployées. Voici le contenu du fichier que vous devez créer :

    user@host:~ $ cat /etc/letsencrypt.sh/hook.sh
    #!/bin/sh
    [ "$1" != "deploy_cert" ] || service apache2 restart
    
N'oubliez pas de le rendre executable :

    user@host:~ $ sudo chmod +x /etc/letsencrypt.sh/hook.sh

## Création du certificat

La commande ``letsencrypt.sh`` avec l'option ``-c`` permet de lancer le processus de création de certificat :

    user@host: $ sudo letsencrypt.sh -c
    # INFO: Using main config file /etc/letsencrypt.sh/config.sh
    # INFO: Using additional config file /etc/letsencrypt.sh/conf.d/config.sh
    Processing example.org with alternative names: www.example.org
     + Signing domains...
     + Generating private key...
     + Generating signing request...
     + Requesting challenge for example.org...
     + Requesting challenge for www.example.org...
     + Responding to challenge for example.org...
     + Challenge is valid!
     + Responding to challenge for www.example.org...
     + Challenge is valid!
     + Requesting certificate...
     + Checking certificate...
     + Done!
     + Creating fullchain.pem...
     + Done!

Vos clés privées et publiques ainsi que votre certificat est maintenant disponible dans le répertoire ``/var/lib/letsencrypt.sh/certs/example.org/`` (où *example.org* est votre domaine principal).

Référez vous à la section [Erreurs classiques](#Erreurs classiques) si l'execution de letsencrypt.sh se termine par une erreur que vous ne comprenez pas.

## Utilisation des certificats dans Apache

Vu qu'il est possible de générer plusieurs certificats pour une même machine, il est préférable de configurer les virtual hosts sur votre apache en ajoutant la directive ``NameVirtualHost *:443`` au début du fichier ``/etc/apache2/sites-enabled/default-ssl.conf`` :

    <IfModule mod_ssl.c>
        NameVirualHost *:443
        <VirtualHost *:443>
                ServerAdmin webmaster@localhost
    [...]

Assurez vous que la balise ``VirtualHost`` reprenne strictement la même chaine de caractère (``*:443``) que ``NameVirualHost``.

Vous pouvez ensuite créer autant de fichier de configuration que vous avez de certificat ssl. Dans notre exemple, pour le certificat lié à *example.org*, nous créons un fichier ``001-ssl-example.org.conf`` dans ``/etc/apache2/sites-available/`` qui contient au moins les lignes suivantes :

    <VirtualHost *:443>
        ServerName example.org
        ServerAlias www.example.org
        DocumentRoot /var/www/example.org
        SSLEngine On
        SSLCertificateFile      /var/lib/letsencrypt.sh/certs/example.org/cert.pem
        SSLCertificateKeyFile   /var/lib/letsencrypt.sh/certs/example.org/privkey.pem
        SSLCertificateChainFile /var/lib/letsencrypt.sh/certs/example.org/chain.pem
        <Directory /var/www/example.org>
            Require all granted
        </Directory>
    </VirtualHost>

En n'oubliant pas d'activer ce site :

    user@host:~ $ sudo a2ensite 001-ssl-example.org.conf

Si ne souhaitez n'avoir qu'un seul certificat, vous pouvez juste changer les directives ``SSLCertificateFile``, ``SSLCertificateKeyFile`` et ``SSLCertificateChainFile`` dans le fichier ``/etc/apache2/sites-available/default-ssl.conf`` en les faisant pointer vers les fichiers que vous venez de générer comme dans l'exemple précédent.

Vous pouvez maintenant recharger votre serveur apache qui servira maintenant vos sites en https certifié par *Let's Encrypt* :

    user@host:~ $ sudo service apache2 reload

## Renouvellement de vos certificats

Les certificats *Let's Encrypt* sont valables trois mois. Il convient donc de les renouveler régulièrement. La commande ``letsencrypt.sh`` le fera pour vous régulièrement. Il convient donc juste de l'inscrire dans une crontable, par exemple en créant le fichier ``/etc/cron.weekly/letsencrypt.sh`` avec le contenu suivant :

    #!/bin/bash
    /usr/bin/letsencrypt -c

et en lui donnant les droits en execution :

    user@host:~ $ sudo chmod +x /etc/cron.weekly/letsencrypt.sh

Maintenant, toutes les semaines, votre *letsencrypt.sh* renouvellera votre certificat si il expire dans les 30 prochains jours.

## Erreurs classiques

Voici des solutions pour résoudre des problèmes classiquement rencontrés avec letsencrypt.sh :

### No registration exists matching provided key

    ERROR: An error occurred while sending post-request to https://acme-v01.api.letsencrypt.org/acme/new-authz (Status 403)
    
    Details:
    {
      "type": "urn:acme:error:unauthorized",
      "detail": "No registration exists matching provided key",
      "status": 403
    }

Cette erreur indique que la clée privée de votre instance letsencrypt n'est pas reconnue par le webservice. C'est sans doute que cette clé a été créée pour un autre webservice (le bac à sable, par exemple) ou qu'une erreur est survenue lors de son enregistrement.

Il faut donc en crééer une nouvelle. Pour se faire, il suffit de supprimer la clé existante :

    user@host:~ $ sudo rm /var/lib/letsencrypt.sh/private_key.json
    user@host:~ $ sudo rm /var/lib/letsencrypt.sh/private_key.pem

Il est également préférable de supprimer les certificats existants :

    user@host:~ $ sudo rm -rf /var/lib/letsencrypt.sh/certs/*

### Provided agreement does not match the current one


    Provided agreement URL [https://letsencrypt.org/documents/LE-SA-v1.0.1-July-27-2015.pdf] 
    does not match current agreement URL [https://letsencrypt.org/documents/LE-SA-v1.1.1-August-1-2016.pdf]

Ce message indique que la licence d'utilisation que vous avez choisi ne correspond pas à celle demandée par *Let's Encruyt*. Il faut donc que vous changier la variable ``LICENSE`` de votre fichier de configuration ``/etc/letsencrypt.sh/conf.d/`` pour y indiquer la seconde URL indiquée dans le message d'erreur.


