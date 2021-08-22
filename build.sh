#!/bin/sh

pip install -r requirements.txt

mkdir site

# copy images to the site
cp -r img docs_en
cp -r img docs_de

# build english
cp -r docs_en docs
mkdocs build --site-dir site/en
rm -r docs

# build german
cp -r docs_de docs
mkdocs build --site-dir site/de
rm -r docs

# add _redirects to deployment
mv _redirects site

# add service setup scripts to deployment
mv service_scripts site/scripts
