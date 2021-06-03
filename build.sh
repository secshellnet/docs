#!/bin/sh

$(which python3) -m pip install mkdocs-material mkdocs-git-revision-date-plugin mkdocs-git-revision-date-localized-plugin
$(which python3) -m mkdocs build
