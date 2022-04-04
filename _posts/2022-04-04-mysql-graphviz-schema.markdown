---
title: Création d'une visualisation de schema SQL
date:  2022-04-04 09:30
layout: post
---

# Installation des dépendances

     sudo apt install python3-sadisplay graphviz

# Création du fichier graphviz

    sadisplay -u "mysql://user:password@host/database" > schema.dot

# Création de l'image de visualisation du schéma SQL

    dot -Tpng schema.dot > schema.png