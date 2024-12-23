---
title: Réception de mail exim Mailing to remote domains not supported
date:  2021-10-07 11:00
layout: post
---

# Description du problème « Mailing to remote domains not supported »

Un serveur envoi de manière intempestive des mails au sujet « Mail delivery failed: returning message to sender » dont une partie du contenu :

    This message was created automatically by mail delivery software.

    A message that you sent could not be delivered to one or more of its
    recipients. This is a permanent error. The following address(es) failed:

      mail@example.org
         (generated from actualys@localhost)
         Mailing to remote domains not supported

La suite du message peut contenir des mails administratifs du type compte-rendu de crontab.

# Mail frozen

Avec la commande `mailq`, vérifiez qu'il existe bien des mails dans un état `frozen` afin de vous assurez que les notifications viennent bien de cette machine :

    $ mailq
    17h  2.0K 1mYA7M-0002Z6-16 <> *** frozen ***
          mail@example.org

    17h  2.0K 1mYACA-0002a6-60 <> *** frozen ***
          mail@example.org

L'envoi de ces mails est donc retenté régulièrement par exim.

# Reconfiguration d'exim

Avec la commande `dpkg-reconfigure`, reconfigurez exim

    $ sudo dpkg-reconfigure exim4-config

Veillez au domaine associé à votre configuration exim pour qu'elle ne corresponde pas à une autre machine que la votre.

# Purge des mails frozen

Pour nettoyer les mails `frozen`, executez la commande suivante :

    $ sudo mailq | grep frozen | awk '{print $3}' | sudo xargs exim -Mrm

Assurez-vous que la `queue` de mails reste bien vide quelques minutes plus tard (notamment si des crons s'executent régulièrement).

    $ sudo mailq
