#! /bin/bash
docker build -t helm-linter tools/helm
docker run --rm -v `pwd`/charts/$1:/toLint/$1 helm-linter lint $1
