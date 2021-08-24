#!/bin/sh

pip install -r requirements.txt

mkdir site

# copy images to the site
cp -r img docs_en
cp -r img docs_de

# copy videos to the site
cp -r video docs_en
cp -r video docs_de

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
mv scripts site/scripts
