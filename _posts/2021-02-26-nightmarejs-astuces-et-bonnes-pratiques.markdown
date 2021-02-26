---
title: Quelques bonne pratiques et astuces avec nightmarejs
date:  2021-02-26 12:00
layout: post
---

# Quelques bonne pratiques et astuces avec nightmarejs


## Compartimenter les actions

Compartimenter les actions permet de pouvoir continuer l'éxécution en cas d'erreur pour une navigation dont les actions ne sont pas dépendantes les unes des autres.

```
nightmare
  .goto(urlLogin)
  .wait('body')
  .then(function() {
      console.log("Récupération de l'html de la page 1");

      return nightmare
        .goto(urlPage1)
        .wait('body')
        .html('mapage1.html');
        .catch(error => {console.error('Search failed:', error)})
  })
  .then(function() {
      console.log("Récupération de l'html de la page 2");

      return nightmare
        .goto(urlPage2)
        .wait('body')
        .html('mapage2.html');
        .catch(error => {console.error('Search failed:', error)})
  })
  .then(function() {
      console.log("Récupération de l'html de la page 3");

      return nightmare
        .goto(urlPage3)
        .wait('body')
        .html('mapage3.html');
        .catch(error => {console.error('Search failed:', error)})
  })
  .then(function() {
      nightmare.end
  });
```

## Chainer les actions qui dépendes les unes des autres


```
nightmare
  .goto(urlLogin)
  .wait('body')
  .then(function() {
      console.log("Screenshot de l'étape 1");

      return nightmare
        .goto(urlPage)
        .wait('#buttonNextEtape1')
        .screenshot('etape1.jpg')
        .click('#buttonNextEtape1')
        .then(function() {
            console.log("Screenshot de l'étape 2");

            return nightmare
                .wait('#buttonNextEtape2')
                .screenshot('etape2.jpg')
                .click('#buttonNextEtape2')
                .then(function() {
                    console.log("Screenshot de l'étape 3");

                    return nightmare
                        .wait('#buttonNextEtape3')
                        .screenshot('etape3.jpg')
                        .click('#buttonNextEtape3')
                        .end()
                })
        })
  })
```


## Réaliser un «if»

```
nightmare
  .goto(url)
  .wait('body')
  .exists('#monbouton') /* Test si un bouton existe et permet d'utiliser l'existence dans la fonction then */
  .then(function(exist) {
      if(!exist) {
          console.log("Le bouton n'existe pas");

          return nightmare;
      }
      console.log("Export html de la page après clique sur le bouton");

      return nightmare
        .click('#monelement')
        .html('monfichier.html')
        .end();
  })
```

## Faire une boucle

```
nightmare
  .goto(url)
  .wait('table#montableau')
  .evaluate(function() {
        return $('table#montableau a').length
   })
  .then(function(nbLink) {
      for(var i = 0; i < nbLink; i++) {
          console.log("Export html de la page"+i);

          nightmare
            .click("table#montableau :nth-child("+i+")")
            .wait('body')
            .html('mapage_'+i+'.html')
            .back()
      }

      return nightmare.end();
  })
```
