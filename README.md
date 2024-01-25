# A sysroot builder

Useful for C/C++ cross-compilers.

## Usage

```
docker buildx build . --output=type=local,dest=/tmp --platform=linux/amd64,linux/arm64

# output files are now in /tmp/sysroot-*.tar.xz
```
