---
title: Prendre en compte les fichiers .editorconfig dans atom
date:  2021-03-09 17:00
layout: post
author: "Vincent LAURENT"
---

# Prendre en compte les fichiers .editorconfig dans atom

## Installer le plugin 

    apm install editorconfig

## Configurer atom

Il est nécessaire de s'assurer qu'aucune configuration d'atom va aller s'opposer aux règles définies dans le fichier .editorconfig

Dans les `Settings` de l'`Editor` passer `TabType` à `auto`

Désactiver le plugin [whitespace](https://atom.io/packages/whitespace)

    apm disable whitespace




