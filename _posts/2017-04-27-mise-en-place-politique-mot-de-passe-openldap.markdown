---
title: Mise en place d'une politique de mot de passe sous OpenLDAP
date:  2017-04-27 14:00
layout: post
---

# Mise en place d'une politique de mot de passe sous OpenLDAP

LDAP propose un module "password policy enforcement" qui permet de forcer les utilisateurs à changer régulièrement leur mot de passe ou à définir un niveau de complexité pour ces dernierrs.

OpenLDAP met à disposition un module, ``ppolicy``, qui permet de mettre en oeuvre cette politique. La commande  ``man slapo-ppolicy`` explique le détails des options disponibles. Cette document est accessible en ligne notamment [sur le site d'OpenLDAP](http://www.openldap.org/software/man.cgi?query=slapo-ppolicy&sektion=5&apropos=0&manpath=OpenLDAP+2.3-Release).

Ce tuto explique comment mettre en oeuvre une politique de mot de passe qui ne s'applique que sur des comptes particuliers.

## S'assurer que le moulde *ppolicy* soit activé

Pour un OpenLDAP dont la configuration est réalisée sous la forme de fichier, il faut au moins que les directives suivantes soient active :

    $ grep ppolicy /etc/openldap/slapd.conf
    moduleload ppolicy.la
    overlay ppolicy

## Une politique *ppolicy* par défaut obligatoire

Le module ``ppolicy`` demande une politique par défaut. La première étape est donc de créer un objet LDAP qui implémente cette politique par défaut.

Pour ce faire, il faut créer un fichier *ldif* introduisant un noeud ``ou=ppolicy`` dans notre LDAP puis un objet ``cn=default`` :

    dn: ou=pwpolicies,dc=example,dc=org
    objectClass: top
    objectClass: organizationalUnit
    ou: pwpolicies

    dn: cn=default,ou=pwpolicies,dc=example,dc=org
    objectClass: pwdPolicy
    cn: default
    pwdMaxAge: 0
    pwdAttribute: userPassword
    pwdExpireWarning: 0
    pwdInHistory: 0
    pwdCheckQuality: 0
    pwdMaxFailure: 0
    pwdLockout: FALSE
    pwdLockoutDuration: 0
    pwdGraceAuthNLimit: 0
    pwdFailureCountInterval: 0
    pwdMustChange: FALSE
    pwdMinLength: 0
    pwdAllowUserChange: TRUE
    pwdSafeModify: TRUE

La commmande ``ldapadd`` permet d'ajouter ces éléments dans le LDAP :

    $ ldapadd -x -h ldap.example.org -D 'cn=Manager,dc=example,dc=org' -W  -f default_ppolicy.ldif

Dans notre exemple, la politique par défaut n'ajoute aucune règle particulière.

## Activer la politique par défaut

Pour que cette politique soit prise en compte par OpenLDAP, il faut y faire référence dans le fichier de configuration ``slapd.conf`` en ajoutant la ligne suivante :

    ppolicy_default cn=default,ou=pwpolicies,dc=example,dc=org

## Ajouter une politique de renouvellement de mot de passe

Nous allons ajouter une politique nommée "restriction" qui obligera les utilisateurs à changer leur mot de passe si ils ne l'ont pas fait depuis un an (365 jours soit 31523000 secondes).

    $ cat policy.ldif
    dn: cn=restriction,ou=pwpolicies,dc=example,dc=org
    cn: restriction
    objectClass: pwdPolicy
    objectClass: organizationalRole
    pwdAttribute: userPassword
    pwdExpireWarning: 259200
    pwdMaxAge: 31536000

    $ ldapadd -x -h ldap.example.org -D 'cn=Manager,dc=example,dc=org' -W  -f policy.ldif

L'attribut ``pwdMaxAge`` indique la durée de vie maximum d'un mot de passe. Pour chaque modification de mot de passe, OpenLDAP met à jour un attribut ``pwdChangedTime``. C'est cette date qui est prise en compte dans le calcul. La durée de vie est indiquée en **secondes**.

L'attribut ``pwdExpireWarning`` permet d'envoyer un message d'alerte à l'utilisateur pour l'inviter à changer son mot de passe. La valeur indique le nombre de secondes avant l'expiration du mot de passe.

L'attribut ``pwdAttribute`` est un attribut obligatoire de tout object ``pwdPolicy``. Il indique où se trouve le mot de passe dans l'objet dédié aux utilisateurs.

## Activer la politique pour certains comptes

Pour chacun des comptes pour lesquels nous voudrons que la politique de durée de vie des mots de passe s'applique, nous devrons indiquer le ``cn`` de cette politique via l'attribut ``pwdPolicySubentry`` :

    $ cat modify.ldif
    dn: uid=login,ou=People,dc=example,dc=org
    add: pwdPolicySubentry
    pwdPolicySubentry: cn=restriction,ou=pwpolicies,dc=example,dc=org

    $ ldapmodify  -x -h ldap.example.org  -D 'cn=XXXXXXXXX,dc=example,dc=org' -W < modify.ldif

## Tester la politique pour un compte

Afin de tester, il faut modifier la date de dernière modification du mot de passe pour attribuer à notre utilisateur de test une date de plus d'un an. Attention, il faut être super utilisateur pour pouvoir le faire et "forcer" ldap à outre passer sa règle de cohérence avec l'option ``-e relax`` :

    $ cat modify.ldif
    dn: uid=login,ou=People,dc=example,dc=org
    changetype: modify
    replace: pwdChangedTime
    pwdChangedTime: 20001231235959Z

    $ ldapmodify -e relax  -x -h ldap.example.org  -D 'cn=XXXXXXXXX,dc=example,dc=org' -W < modify.ldif

Une fois réalisé, si la politique est bien appliqué on obtient :

    $ ldapwhoami  -x -h ldap.example.org  -D 'uid=login,ou=People,dc=example,dc=org' -W
    Enter LDAP Password:
    ldap_bind: Invalid credentials (49)

Pour être sur qu'il ne s'agit pas d'une erreur de frappe, on a le message suivant dans le fichier de log ``/var/log/openldap.log`` :

    Apr 27 12:00:00 ldap slapd[XXXXX]: ppolicy_bind: Entry dn: uid=login,ou=People,dc=example,dc=org has an expired password: 0 grace logins
