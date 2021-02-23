# LFTP : Résoudre une erreur « Host key verification failed » sftp

Suite au renouvellement de certains serveur sftp, lftp retourne une erreur « *Host key verification failed* » :

    user@localhost:~ $ lftp -p 21 -u user,****  sftp://10.1.1.160
    lftp user@10.1.1.160:~> ls
    ls: Erreur fatale: Host key verification failed
    lftp user@10.1.1.160:~> exit

Le problème vient du fait que l'ancienne clé publique du serveur (10.1.1.160) n'est plus valide. 

Pour la gestion du chiffrement, LFTP se repose sur ssh. ssh peut donc vous aider à résoudre ce problème.

## Vérification du dignostic avec ssh

    user@localhost:~ $ ssh -p 21 10.1.1.160 
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
    Someone could be eavesdropping on you right now (man-in-the-middle attack)!
    It is also possible that a host key has just been changed.
    The fingerprint for the RSA key sent by the remote host is
    00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00.
    Please contact your system administrator.
    Add correct host key in /home/actualys/.ssh/known_hosts to get rid of this message.
    Offending RSA key in /home/user/.ssh/known_hosts:6
      remove with: ssh-keygen -f "/home/actualys/.ssh/known_hosts" -R [10.1.1.160]:21
    RSA host key for [10.1.1.160]:21 has changed and you have requested strict checking.
    Host key verification failed.

## Correction avec ssh

Comme l'indique la commande ssh, il faut supprimer la clé dans le fichier ``known_hosts`` :

    ssh-keygen -f "/home/actualys/.ssh/known_hosts" -R [10.1.1.160]:21

Puis en rééxcutant la commande ssh, on pourra intégrer la nouvelle clé :

    ssh -p 21 10.1.1.160

En saisissant ``yes``, la clé est acceptée et la commande lftp refonctionne normalement.



