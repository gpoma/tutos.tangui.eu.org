---
title: Deployer Let's Encrypt sous Debian grace à dehydrated
date:  2016-08-09 14:00
layout: post
---

[Let's Encrypt](https://letsencrypt.org/) est projet qui permet de déployer des certificats https sans avoir recours à des autorités de certification payantes. L'appel à un webservice du projet *letsencrypt* permet de vérifier l'authenticité de la demande et de certifier les clés liés à un nom de domaine.

Ce projet s'interconnecte donc avec le serveur HTTP sur lequel vous souhaitez déployer les certificats HTTPS afin de répondre positivement à ce dialogue d'authentification.

Les certificats seront renouvelés automatiquement via une cron.

## Installation des packets Debian nécessaires

Une majorité des versions de Debian suppporte ``dehydrated``, le projet qui simplifie la gestion des certificats *letsencrypt*. A partir de ``stretch``, le projet est intégré. Pour ``jessie``, un backport est proposé. Pour ``wheezy``, les packets deb fonctionnent. Voici donc les procédures d'installation pour ces différents cas de figures :

### Installer les packets letsencrypt

Pour installer letsencrypt ainsi que les outils de dialogue avec le webservice de certification et le renouvellement automatique, vous pouvez installer le packet ``dehydrated-apache2`` (anciennement ``letsencrypt.sh-apache2``) (si vous utilisez apache2 comme serveur http/https) :

    user@host:~ $ sudo aptitude install dehydrated-apache2

Ce packet va installer ``dehydrated`` (les scripts shell permettant la création et le renouvellement autormatique) en plus des éléments nécessaires à l'authentification des domaines via apache.

### Sous jessie, installer de dépot jessie-backport

Contrairement aux versions, plus récente de Debian, les packets Debian ne sont pas disponibles de base pour Jessie mais Debian les met à disposition via le dépot *jessie-backport*. Pour activer ce dépot, vous pouvez créer un fichier source.list pour apt dans le répertoire ``/etc/apt/sources.list.d/`` ayant comme nom par exemple ``backports.list`` avec le contenu :

    deb http://ftp.us.debian.org/debian/ jessie-backports main

Une fois ajouté, il faut mettre à jour apt avec la commande ``sudo aptitude update`` pour que le dépot soit intégré dans votre instance apt.

### Sous wheezy, installer manuellement les .deb

Sous wheezy, aucun débpot ne propose ``dehydrated``. En revenche, vous pouvez installer les packets .deb issus de jessie-backport manuellement. Ils fonctionnenet :

    user@host: $ cd /tmp
    user@host: $ wget -q http://ftp.fr.debian.org/debian/pool/main/d/dehydrated/dehydrated_0.3.1-3~bpo8+1_all.deb
    user@host: $ wget -q http://ftp.fr.debian.org/debian/pool/main/d/dehydrated/dehydrated-apache2_0.3.1-3~bpo8+1_all.deb
    user@host: $ sudo dpkg -i dehydrated_*.deb
    user@host: $ sudo dpkg -i dehydrated-apache2_*.deb

Si les commandes wget retournent une 404, c'est qu'il existe une version plus récente. Téléchargez les depuis [packages.debian.org/jessie-backports/dehydrated](https://packages.debian.org/jessie-backports/dehydrated) et [packages.debian.org/jessie-backports/dehydrated-apache2](https://packages.debian.org/jessie-backports/dehydrated-apache2)

## Configuration d'Apache

### S'assurer de la bonne configuration d'apache

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

De même assurez-vous que le ou les domaines que vous comptez utiliser en https pointe bien sur votre machine. Si votre machine a comme adresse ip *10.10.10.10* et que vos domaines sont *example.org* et *www.example.org*, vous devriez avoir :

    user@host: $ host example.org
    example.org has address 10.10.10.10
    user@host: $ host www.example.org
    example.org has address 10.10.10.10

Du coup, ces domaines devraient répondre correctement aux requêtes https :

    user@host: $ curl -sk https://example.org/ | head

    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <title>Apache2 Debian Default Page: It works</title>
        <style type="text/css" media="screen">
          * {
        margin: 0px 0px 0px 0px;
        padding: 0px 0px 0px 0px;

    user@host: $ curl -sk https://www.example.org/ | head

    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <title>Apache2 Debian Default Page: It works</title>
        <style type="text/css" media="screen">
          * {
        margin: 0px 0px 0px 0px;
        padding: 0px 0px 0px 0px;

On utilise l'option ``-k`` car le certificat par defaut sous Debian est un certificat autosigné, ce qui provoque une erreur lors de l'appel curl.

### Activer la configuration dehydrated d'Apache

Le paquet ``dehydrated-apache2`` fournit un fichier de configuration qu'il faut activer en créant un lien symbolique vers le sous répertoire ``conf.enabled`` :

    user@host: $ sudo ln -s /etc/apache2/conf-available/dehydrated.conf /etc/apache2/conf-enabled/

Pour debian Wheezy :

    user@host: $ sudo ln -s /etc/apache2/conf-available/dehydrated.conf /etc/apache2/conf.d/


Pour vérifier que la configuration liée au dialogue d'authentification a bien été pris en compte pour vos domaines :

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

L'erreur ``403`` est normale. En revanche si vous avez une ``404`` c'est que la configuration apache voulue par *dehydrated-apache2* n'est pas prise en compte. Peut être avez vous une directive *RewriteRule* qui bypasse la configuration de ``/etc/apache2/conf-enabled/dehydrated.conf``.

Vérifiez bien que tous les domaines sur lesquels vous cherchez à utiliser HTTPS répondent par une 403.

## Configuration de dehydrated

La configuration se dehydrated se passe en deux temps :

 - la définition des domaines
 - la configuration du processus d'automatisation dehydrated

### Définition des domaines à utiliser

Pour chaque certificat ssl dédié à https, vous allez devoir créer une ligne dans le fichier ``/etc/dehydrated/domains.txt``(anciennement ``/var/lib/letsencrypt.sh/domains.txt``, cette destination est modifiable via la variable DOMAINS_TXT de ``config.sh``). Si un même applicatif http peut être servit depuis plusieurs domaines, vous pouvez créer un certificat pour tous les domaines concernés. Vous aurez donc une ligne par VirtualHost apache2 pour le port *:443 (et donc par ``ServerName`` concerné) et vous inscrirez les ``ServerAlias`` comme domaines secondaires.

Si vous souhaitez créer un certificat pour *example.org* (le ``ServerName`` de votre ``VirtualHost *:443``) lié à un domaine secondaire *www.example.org* (le ``ServerAlias`` lié à *example.org*), votre fichier ``/etc/dehydrated/domains.txt`` contiendra donc la ligne suivante :

    example.org www.example.org

### Configuration du processus d'automatisation

Debian fournit un fichier de configuration général (``/etc/dehydrated/config``). Pour pouvoir faire cohabiter plusieurs configuration, Debian propose de ne pas toucher à ce fichier et créer des sous configurations via le répertoire ``/etc/dehydrated/conf.d/``.

Deux fichiers sont à créer pour gérer l'automatisation des créations et renouvellements des processus :
 - un fichier de configuration
 - un fichier permettant de redémarrer les services impactés

Le fichier de configuration se trouve dans le répertoire ``/etc/dehydrated/conf.d/`` vous pouvez lui donner le nom qui vous convient (pour notre exemple, nous l'appelons ``example.sh``. Il doit contenir la référence à la licence d'utilisation du webservice letsencrypt (variable shell ``LICENSE``), l'adresse email de contact (variable ``CONTACT_EMAIL``) et la référence au script de redémarrage des service (variable ``HOOK``) :

    user@host:~ $ cat /etc/dehydrated/conf.d/example.sh
    HOOK='/etc/dehydrated/hook.sh'
    CONTACT_EMAIL=contact@example.org
    LICENSE="https://letsencrypt.org/documents/LE-SA-v1.1.1-August-1-2016.pdf"

Attention, en production, *letsencrypt* **limite le nombre de requêtes** possibles par domaine à quelques dixaines par jour. Si vous souhaitez utiliser *letsencrypt* en mode bac à sable plutot que directement en interrogeant le webservice de production, vous pouvez ajouter la ligne suivante :

    CA="https://acme-staging.api.letsencrypt.org/directory"

Une fois que vos tests effectués, vous pourrez supprimer cette ligne (ainsi que les fichiers ``/var/lib/dehydrated/private_key.json``, ``/var/lib/dehydrated/private_key.pem`` et tous ceux qui se trouvent dans les sous répertoires de ``/var/lib/dehydrated/certs/``).

Pour le script de redémarrage des services, (que nous avons nommé ``/etc/dehydrated/hook.sh`` dans le fichier de configuration), il permet de redémarrer apache une fois les nouvelles clés déployées. Voici le contenu du fichier que vous devez créer :

    user@host:~ $ cat /etc/dehydrated/hook.sh
    #!/bin/sh
    [ "$1" != "deploy_cert" ] || service apache2 restart

N'oubliez pas de le rendre executable :

    user@host:~ $ sudo chmod +x /etc/dehydrated/hook.sh

## Création du certificat

La commande ``dehydrated`` avec l'option ``-c`` permet de lancer le processus de création de certificat :

    user@host: $ sudo dehydrated -c
    # INFO: Using main config file /etc/dehydrated/config
    # INFO: Using additional config file /etc/dehydrated/conf.d/example.sh
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

Vos clés privées et publiques ainsi que votre certificat est maintenant disponible dans le répertoire ``/var/lib/dehydrated/certs/example.org/`` (où *example.org* est votre domaine principal).

Référez vous à la section [Erreurs classiques](#erreurs-classiques) si l'execution de dehydrated se termine par une erreur que vous ne comprenez pas.

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
        SSLCertificateFile      /var/lib/dehydrated/certs/example.org/cert.pem
        SSLCertificateKeyFile   /var/lib/dehydrated/certs/example.org/privkey.pem
        SSLCertificateChainFile /var/lib/dehydrated/certs/example.org/chain.pem
        <Directory /var/www/example.org>
            Require all granted
        </Directory>
    </VirtualHost>
* La directive Require all granted  est utilisé pour la version d'Apache > 2.2  ( Ref: http://httpd.apache.org/docs/current/upgrading.html )

En n'oubliant pas d'activer ce site :

    user@host:~ $ sudo a2ensite 001-ssl-example.org.conf

Si ne souhaitez n'avoir qu'un seul certificat, vous pouvez juste changer les directives ``SSLCertificateFile``, ``SSLCertificateKeyFile`` et ``SSLCertificateChainFile`` dans le fichier ``/etc/apache2/sites-available/default-ssl.conf`` en les faisant pointer vers les fichiers que vous venez de générer comme dans l'exemple précédent.

Vous pouvez maintenant recharger votre serveur apache qui servira maintenant vos sites en https certifié par *Let's Encrypt* :

    user@host:~ $ sudo service apache2 reload

## Renouvellement de vos certificats

Les certificats *Let's Encrypt* sont valables trois mois. Il convient donc de les renouveler régulièrement. La commande ``dehydrated`` le fera pour vous régulièrement. Il convient donc juste de l'inscrire dans une crontable, par exemple en créant le fichier ``/etc/cron.weekly/dehydrated`` avec le contenu suivant :

    #!/bin/bash
    /usr/bin/dehydrated -c

et en lui donnant les droits en execution :

    user@host:~ $ sudo chmod +x /etc/cron.weekly/dehydrated

Maintenant, toutes les semaines, votre *dehydrated* renouvellera votre certificat si il expire dans les 30 prochains jours.

**Attention**, le fonctionnement de cron.weekly interdit l'usage du caractère «\ .\ » dans le nom des fichiers à executer. Pour cette raison le nom du script ne porte pas le nom du projet mais s'appelle ``dehydrated``.

## Erreurs classiques

Voici des solutions pour résoudre des problèmes classiquement rencontrés avec dehydrated :

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

    user@host:~ $ sudo rm /var/lib/dehydrated/private_key.json
    user@host:~ $ sudo rm /var/lib/dehydrated/private_key.pem

Il est également préférable de supprimer les certificats existants :

    user@host:~ $ sudo rm -rf /var/lib/dehydrated/certs/*

### Provided agreement does not match the current one


    Provided agreement URL [https://letsencrypt.org/documents/LE-SA-v1.0.1-July-27-2015.pdf]
    does not match current agreement URL [https://letsencrypt.org/documents/LE-SA-v1.1.1-August-1-2016.pdf]

Ce message indique que la licence d'utilisation que vous avez choisi ne correspond pas à celle demandée par *Let's Encruyt*. Il faut donc que vous changier la variable ``LICENSE`` de votre fichier de configuration ``/etc/dehydrated/conf.d/`` pour y indiquer la seconde URL indiquée dans le message d'erreur.

### urn:acme:error:connection (400 : Could not connect )

Si l'execution de la commande ``dehydrated -c`` indique une erreur du type :

    user@host: $ dehydrated -c
    # INFO: Using main config file /etc/dehydrated/config
    # INFO: Using additional config file /etc/dehydrated/conf.d/example.sh
    Processing www.example.org
    + Signing domains...
    + Generating private key...
    + Generating signing request...
    + Requesting challenge for www.example.org...
    + Responding to challenge for www.example.org...
    ERROR: Challenge is invalid! (returned: invalid) (result: {
    "type": "http-01",
    "status": "invalid",
    "error": {
    "type": "urn:acme:error:connection",
    "detail": "Could not connect to www.example.org",
    "status": 400
    },
    [...]

C'est que le domaine ``www.example.org`` n'est pas accessible publiquement. Les serveurs de *letsencrypt* ne peuvent donc vérifier que vous êtes propriétaire du domaine et refusent donc de certifier vos clés.
