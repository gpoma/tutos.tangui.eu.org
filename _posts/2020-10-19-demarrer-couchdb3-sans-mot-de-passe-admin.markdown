---
title: Démarrer couchdb 3 sans mot de passe admin
date:  2020-10-19 12:17
layout: post
---

Depuis la version 3 de couchdb on ne peut plus démarrer le service sans avoir configuré un mot de passe admin, si on essaye de le faire quand même le message suivant s'inscrit dans les logs couchdb puis le service s'arrête :

> -------- No Admin Account configured. Please configure an Admin Account in your local.ini file and restart CouchDB.

Il existe cepedant une astuce si on souhaite quand même le faire.

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
