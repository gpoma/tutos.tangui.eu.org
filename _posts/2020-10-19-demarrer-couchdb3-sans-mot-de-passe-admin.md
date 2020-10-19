---
title: Démarrer couchdb 3 sans mot de passe admin
date:  2020-10-19 12:17
layout: post
---

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
