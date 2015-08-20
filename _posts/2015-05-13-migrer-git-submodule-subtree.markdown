---
title: Migrer des submodules git en subtrees
date:  2015-05-13 23:44
layout: post
---

Si les submodules sont pratiques et utiles pour brancher une librairie extérieure à un projet sans avoir a en intégrer le code, ils sont beaucoup moins pratiques lorsqu'on doit en modifier le contenu régulièrement.

Pour ce cas, les subtree sont beaucoup plus pratiques.

De plus, le subtree permettra aux utilisateurs de votre dépot à avoir accès au contenu du dépot externe sans avoir à faire de manipulation.

Si vous souhaitez donc abandonner l'usage de submodule pour adopter les subtrees, voici une procédure de migration.

##Identifier le commit de votre submodule

Un submodule lie le dépot courrant à un *commit* d'un projet externe. Si vous souhaitez donc migrer la partie de votre dépot utilisant *git submodules* vers un subtree, il faut identifier ce commit.

Pour le faire, déplacez vous dans le répertoire du submodule :

    $ cd plugin/theExternalLib

**NB** : plugin/theExternalLib est le chemin du submodule tel qu'il a été déclaré dans le fichier *.gitmodules* qui se trouve à la racine de votre dépot.

et demandez à git le dernier commit :

    $ git log | head -n 5
    commit e5ffab7f5bef95c5af0fd3ba262c8331e61e0d12
    Author: Anne Onime <anne.onime@example.org>
    Date:   Tue May 12 12:21:05 2015 +0200

    	    last commit

L'identifiant du dernier commit est pour cet exemple e5ffab7f5bef95c5af0fd3ba262c8331e61e0d12

Si vous ne connaissez pas l'url utilisé pour ce submodule, vous pouvez le consulter dans le fichier *.gitmodules* qui se trouve à la racine de votre dépot :

    [submodule "plugin/theExternalLib"]
        path = plugin/theExternalLib
	url = git@github.com:plugin/externallib.git

##Retirer le submodule

Pour utiliser le submodule vous avez du l'initialiser avec la commande *git submodules init*. Pour le retirer du projet, il faut donc retirer cette initalisation avec la commande :

    $ git submodules deinit plugin/theExternalLib

**NB** : changez *plugin/theExternalLib* par le chemin de votre submodule ;-)

##Supprimer le répertoire hébergeant le submodule

La commande *git subtree* refusera de créer le subtree si le répertoire du submodule est encore présent. Il faut donc le retirer :

    $ rm -rf plugin/theExternalLib/
    $ git rm -f plugin/theExternalLib

Ce répertoire ayant été déclaré dans la configuration du submodule, il fait le retirer de *.gitmodules* puis informer git de la modification ou la suppression de ce fichier :

    $ git add .gitmodules

ou

    $ git rm .gitmodules

Et commiter ce changement :

    $ git commit "suppression du submodule" 

##Ajouter le dépot du submodule comme dépot distant et le récupérer

Pour brancher le contenu de notre submodule au dépot, il faut le déclarer comme dépot distant :

    $ git remote add theExternalLib git@github.com:plugin/externallib.git

NB: remplacer *theExternalLib* par le nom que vous donnez à ce dépot externe ainsi que l'url de ce dernier

Demandez à git de télécharger le contenu de ce dépot :

    $ git fetch theExternalLib

NB: *theExternalLib* correspond au nom choisi lors de la commande git précédente

Maintenant notre git possède la base des commits de l'ensemble du dépot distant. Il n'aura donc pas de mal à repérer le commit que notre submodule utilisait.

##Intégrer comme subtree le dépot distant

Nous pouvons donc maintenant créer un subtree qui intégrera notre dépot externe jusqu'au commit repéré :

    $ git subtree add --prefix=plugin/theExternalLib  e5ffab7f5bef95c5af0fd3ba262c8331e61e0d12 --squash

NB : remplacez *plugin/theExtranalLib* par le chemin où doit être intégrer le dépot externe et *e5ffab7f5bef95c5af0fd3ba262c8331e61e0d12* par le commit repéré plus tot.

L'option *--squash* permet de ne pas intégrer tous les commits du dépot externe, ainsi votre dépot ne sera pas alourdi des commits de ce projet (et les contributeurs du projet n'apparaisseront pas comme contributeurs du votre).

Le répertoire *plugin/theExternalLib* héberge maintenant le contenu du dépot externe et le subtree apparait dans le log de votre projet :

    $ git log | head
    commit fc886b4b6d4b722710848bc1dcc4fe0f43f9575e
    Author: Tangui Morlier <tangui@tangui.eu.org>
    Date:   Wed May 13 15:20:43 2015 +0200

    Squashed 'plugins/theExternalLib/' content from commit e5ffab
    
    git-subtree-dir: plugins/theExternalLib
    git-subtree-split: e5ffab7f5bef95c5af0fd3ba262c8331e61e0d12

Bravo !

Malheureusement, si vous avez plusieurs submodules dans votre projet, vous devez réaliser cette procédure pour chacun d'entre eux :-(
