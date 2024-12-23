---
title: Retrouver un document couchdb supprimé
date:  2017-10-10 11:30
layout: post
author: "Vincent LAURENT"
---

# Retrouver un document couchdb supprimé

Le paramètre open_revs=all et revs=true permet d'afficher toutes les révisions d'un document

> curl http://localhost:5984/database_name/document_id?open_revs=all&revs=true

    {
    "_id":"document_id",
    "_rev":"4-1db2abbc93c0f3501e9bf8e43ef11635",
    "_deleted":true,
    "_revisions":
        {
        "start":4,
         "ids":[
                "1db2abbc93c0f3501e9bf8e43ef11635",
                "743721e1d27b9791d4fddf926d2d18f6",
                "e69a6bb2c1e3c2522238c470709fb5a1",
                "2f8abc9bb9b19c28b8154f2a830ce814"
                ]
         }
    }
    
Le tableau d'ids contient les différentes révisions, la première étant la plus récente soit :

- 4-1db2abbc93c0f3501e9bf8e43ef11635
- 3-743721e1d27b9791d4fddf926d2d18f6
- 2-e69a6bb2c1e3c2522238c470709fb5a1
- 1-2f8abc9bb9b19c28b8154f2a830ce814

Ici la version 3 devrait contenir notre document avant suppression que l'on peut récupérer ainsi :

> curl http://localhost:5984/database_name/document_id?rev=3-743721e1d27b9791d4fddf926d2d18f6
