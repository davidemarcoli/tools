# Tools

## Publishing

### Committing

```bash
git add .
git commit -m "feat: add command line options for filtering by file extension and path"
git push origin main
```

### Tagging

```bash
git tag -a v1.1.0 -m "Version 1.1.0 add command line options for filtering by file extension and path"
git push origin v1.1.0
```

### Brew Formula

```bash
wget https://github.com/davidemarcoli/tools/archive/refs/tags/v1.1.0.tar.gz
shasum -a 256 v1.1.0.tar.gz
```

Edit the `homebrew-tools` repository and update the `.rb` file with the new version and sha256.