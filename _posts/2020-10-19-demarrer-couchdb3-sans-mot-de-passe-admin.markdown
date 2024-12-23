---
title: Démarrer couchdb 3 sans mot de passe admin
date:  2020-10-19 12:17
layout: post
author: "Vincent LAURENT, Gabriel POMA"
---

Depuis la version 3 de couchdb on ne peut plus démarrer le service sans avoir configuré un mot de passe admin, si on essaye de le faire quand même le message suivant s'inscrit dans les logs couchdb puis le service s'arrête :

> -------- No Admin Account configured. Please configure an Admin Account in your local.ini file and restart CouchDB.

Il existe cepenant une astuce pour contourner ce contrôle.

Ajouter la ligne suivante dans le script bash d'éxécution de couchdb /opt/couchdb/bin/couchdb :

```
export COUCHDB_TEST_ADMIN_PARTY_OVERRIDE=1
```

Supprimer le fichier /opt/couchdb/etc/local.d/10-admins.ini

```
rm /opt/couchdb/etc/local.d/10-admins.ini
```

Redémarrer le service couchdb

```
service couchdb restart
```

## Méthode alternative : systemD

Une autre solution consiste à exporter la variable d'environnement dans le fichier du service systemD. La *bonne pratique actuelle* est de créer un fichier *override.conf*.

```
systemctl edit couchdb
```

Cela va créer un répertoire */etc/systemd/system/couchdb.service.d/* pour y stocker le fichier *override.conf* et sera lu automagiquement. Cela permet d'avoir un fichier central qui permet d'altérer ou d'ajouter de la configuration fournie par la distribution, persistante à une montée de version ou de changement de configuration de la distribution.


Il suffit donc d'ajouter les lignes suivantes pour ajouter la variable d'environnement :

    [Service]
    Environment="COUCHDB_TEST_ADMIN_PARTY_OVERRIDE=1"
