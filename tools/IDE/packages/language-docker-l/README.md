# Atom Docker Syntax Highlighting

Atom syntax highlighting for Dockerfiles.

## Install

Install the package `language-docker-l` in Atom (Preferences->Packages) or Atom's package manager from a shell:

```bash
$ apm install language-docker-l
```

## What we support
This package supports most of Dockerfiles syntax that includes the .dockerignore file as well


## Enable Highlighting for  `Dockerfile.<suffix>`

[Unsupported] - Highlighting is based on wildcards and is not supported by Atom.
[file.types] Use this package to enable the functionality [file-types](https://atom.io/packages/file-types)


Snippet to use:
```cson
  "file-types": {
    "^Dockerfile\\..*$": "source.dockerfile"
  }
```
