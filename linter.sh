#! /bin/bash
docker build -t helm-linter tools/helm
docker run --rm -v `pwd`/charts/Nextcloud:/toLint helm-linter
