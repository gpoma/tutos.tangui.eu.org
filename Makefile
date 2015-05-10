all: about.md index.html _posts/* css/*
	jekyll build
	cp .htaccess _site/.htaccess
