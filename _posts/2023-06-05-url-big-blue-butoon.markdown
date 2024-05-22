---
title: "Conserver la compatibilité des url Big Blue Button"
date:  2023-06-05 15:00
layout: post
---

En changeant de version de Greenlight de la version 2 à la version 3 (big blue button 2.4 à 2.6), les url des chambres ont changées.

Les chambres avaient des url de type `bbb.example.org/b/id-de-ma-chambre`, elles sont maintenant accessibles depuis `bbb.example.org/rooms/id-de-ma-chambre`

Pour conserver la compatibilité après la migration, il faut ajouter une redirection nginx en créant un fichier `/etc/bigbluebutton/nginx/oldurl.nginx` avec le contenu :

    rewrite ^/b/(.*)$ /rooms/$1 permanent;
