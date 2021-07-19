#!/bin/sh

pip install -r requirements.txt

mkdir site

# copy images to the site
cp -r img docs_en
cp -r img docs_de

# add service scripts to service folders
cp service_scripts/* docs_en/2._Services
cp service_scripts/* docs_de/2._Services

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
