---
title: Copier un document couchdb
date:  2021-09-17 09:37
layout: post
author: "Vincent LAURENT"
---

# Copier un document couchdb

La documentation couchdb de la copie d'un document est décrite ici : https://docs.couchdb.org/en/stable/api/document/common.html#copying-from-a-specific-revision

Dans la requète http il faut utiliser la méthode `COPY` et l'entête `Destination: new_document_id` pour indiquer le nouvel id de document : 

    curl -X COPY http://localhost:5984/database_name/document_id -H 'Destination: new_document_id'


