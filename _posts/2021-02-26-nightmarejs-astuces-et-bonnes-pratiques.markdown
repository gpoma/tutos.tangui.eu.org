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
      return nightmare
        .goto(urlPage1)
        .wait('body')
        .html('mapage1.html'); /* Exporte la page en html */
        .catch(error => {console.error('Search failed:', error)})
  })
  .then(function() {
      return nightmare
        .goto(urlPage2)
        .wait('body')
        .html('mapage2.html'); /* Exporte la page en html */
        .catch(error => {console.error('Search failed:', error)})
  })
  .then(function() {
      return nightmare
        .goto(urlPage3)
        .wait('body')
        .html('mapage3.html'); /* Exporte la page en html */
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
      return nightmare
        .goto(urlPage)
        .wait('#buttonNextEtape1')
        .screenshot('etape1.jpg');
        .click('#buttonNextEtape1')
        .then(function() {
            return nightmare
                .wait('#buttonNextEtape2')
                .screenshot('etape2.jpg');
                .click('#buttonNextEtape2')
                .then(function() {
                    return nightmare
                        .wait('#buttonNextEtape3')
                        .screenshot('etape3.jpg');
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
  .exists('#monelement') /* Test si l'élément existe et permet d'utiliser ce test dans la fonction then */
  .then(function(exist) {
      if(!exist) {

          return nightmare;
      }

      return nightmare
        .click('#monelement')
        .html('monfichier.html'); /* Exporte la page en html */
  })
```

## Faire une boucle

```
nightmare
  .goto(url)
  .wait('table#montableau')
  .evaluate(function() {
        return $('table#montableau a').length
  .then(function(nbLink) {
      for(var i = 0; i < nbLink; i++) {
          nightmare
            .click("table#montableau :nth-child("+i+")")
            .wait('body')
            .html('mapage_'+i+'.html')
            .back()
      }

      return nightmare;
  })
```
