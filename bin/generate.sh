#!/bin/bash

for brut in [0-9] [0-9][0-9] ; do 
	perl drupal2jekyll.pl < $brut > $brut".html" 2> $brut".markdown" ; 
	pandoc -f html -t markdown  $brut".html" >> $brut".markdown" ; 
	rm $brut".html"  ; 
	date=$(grep date: $brut.markdown  | sed 's/date:   //' | sed 's/ .*//') ; 
	mv $brut".markdown" ../_posts/$date"-node"$brut".markdown" ; 
done
