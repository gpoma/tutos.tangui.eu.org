all: _site/index.html

_site/index.html: about.md index.html _posts/* css/* .htaccess
	jekyll build
