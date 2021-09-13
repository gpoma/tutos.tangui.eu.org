---
title: Problème decriture du lock solr avec tomcat 9
date:  2021-08-31 21:00
layout: post
author: "Tangui Morlier"
---

# Problème d'écriture du fichier de lock SOLR avec tomcat 9

Suite à une migration de tomcat8 à tomcat9 sous Debian, Solr n'arrive plus à écrire en la base lucenne.

Les exceptions suivantes sont renvoyés (dans le fichier `/var/log/tomcat9/catalina.out` : 

    java.lang.RuntimeException: Failed to acquire random test lock; please verify filesystem for lock directory './solr/data/index' supports locking

ou :

    org.apache.lucene.store.LockReleaseFailedException: Cannot forcefully unlock a NativeFSLock which is held by another indexer component: ./solr/data/index/lucene-xxxxxxxxxxxxxxxxxxxxxxxxx-lucene-xxxx-test.lock

Le problème vient d'un problème d'autorisation en écriture de tomcat9 dans la base lucence.

## Vérifier la paternité et les droits du répertoire data et de ses sous-répertoire

Le service Tomcat9 sous debian ne tourne plus sous l'utilisateur `tomcat8` mais `tomcat`. Il faut donc s'assurer que ce démon a les droits pour écrire dans la base hébergée dans le sous répertoire `data` du répertoire de travail solr.

Pour s'en assurer, il faut changer les droits :

    chown -R tomcat.tomcat solr/data
    
    chmod -R u+wX solr/data

## Autoriser les écritures dans la sandbox java

Avec tomcat9, un système de sandboxing a été introduit. Il limite les accès en écriture sur quasi tous les répertoires (Pour plus d'info, voir ce [README Debian](https://salsa.debian.org/java-team/tomcat9/blob/master/debian/README.Debian)).

A moins que le répertoire `data` soit un sous répertoire de `/var/lib/tomcat9/webapps`, il faut l'ajouter comme répertoire autorisé dans `service.d`.

Pour se faire, il suffit d'ajouter un fichier .conf dans le répertoire `/etc/systemd/system/tomcat9.service.d/` (nous avons choisi `override.conf`) contenant les informations suivantes :


      [Service]
      ReadWritePaths=/chemin/absolu/vers/solr/data

(il faut evidemment adapter /chemin/absolu/vers/solr/data à votre configuration)

Cette résolution a été trouvée grace à ce [fil serverfault](https://serverfault.com/questions/989150/application-logging-broken-under-tomcat-9-permission-denied-to-var-log-myapp).
