#!/bin/sh

pip install -r requirements.txt

mkdir site

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
