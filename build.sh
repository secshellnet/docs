#!/bin/sh

mkdir site

# build english
cp -r docs_en docs
mkdocs build --site-dir site/en
rm -r docs

# build german
cp -r docs_de docs
mkdocs build --site-dir site/de
rm -r docs
