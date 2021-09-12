---
title: Autologin avec metabase
date:  2021-09-13 01:07
layout: post
---

# Autologin avec metabase

## S'authentifier avec l'api de metabase
    
Il est possible de s'authentifier à metabase via son api, en incluant par exemple ce code javascript dans une page du même domaine :
    
    var metabase_webpath = '/metabase';
    var username = 'username';
    var password = 'password';

    var xhttp = new XMLHttpRequest();
    xhttp.open("POST", metabase_webpath + "/api/session", false);
    xhttp.setRequestHeader("Content-type", "application/json");
    xhttp.send('{"password":"' + password + '","username":"' + username + '","remember":'+ remember +'}');


Une réponse avec le code http 200 indique une authentification réussi.

## Vérifier si l'utilisateur est authentifié sur metabase

    var metabase_webpath = '/metabase';
    var xhttp = new XMLHttpRequest();
    xhttp.open("GET", metabase_webpath + "/api/user/current", true);
    xhttp.send();
    xhttp.onload = function() {
    	if(xhttp.status != 401) {
    		// Utilisateur déjà authentifié sur metabase
            return;
    	}
        
        // Utilisateur non authentifié
    }

## Insérer du code javascript dans métabase avec Apache

Si metabase est distribué par apache, comme par exemple avec cette configuration :

    <Location "/metabase/">
            ProxyPass http://localhost:3213/
            ProxyPassReverse http://localhost:3213/
            SSLRequireSSL
    </Location>

Il est possible d'insérer du code html dans la réponse http avec les modules apache substitute et filter. Filter est généralement activé de base, il est par contre nécessaire d'activer substitute :

    sudo a2enmod substitute

Puis voici la configuration apache pour insérer un fichier javascript `/js/metabase_autologin.js` dans toute les pages html de métabase :


    <Location "/metabase/">
            Header unset Content-Security-Policy
            RequestHeader unset Accept-Encoding
            AddOutputFilterByType SUBSTITUTE text/html
            Substitute "s#</body>#<script type=\"text/javascript\" src=\"/js/metabase_autologin.js\"></script></body>#ni"
    </Location>


