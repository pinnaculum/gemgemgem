# gemgemgem

A small Python toolkit to work with gemini and
[gempub](https://codeberg.org/oppenlab/gempub) archives.

```sh
pip install .
```

To install the gempub viewer (*GemV*) as well:

```sh
pip install '.[ui]'
```

[Download GemV's latest AppImage (x86_64)](https://gitlab.com/galacteek/gemgemgem/-/releases/continuous-master/downloads/GemV-latest-x86_64.AppImage)

## Convert an epub to gempub

To convert an ebook in the *epub* format to a *gempub* archive,
use the *gempubify* command:

```sh
gempubify book.epub

gempubify -o gembook.gpub book.epub
```

You can also create *gempub* archives by passing the path of
a project file, formatted in YAML.

```sh
gempubify -o manual.gpub docs/gemv/manual/manual.yaml
```

See [the manual's project file](https://gitlab.com/galacteek/gemgemgem/-/blob/master/docs/gemv/manual/manual.yaml) for an example.

If you have access to an IPFS (kubo) daemon and want to import the
gempub file to IPFS, use *--ipfs-import*. The CID of the directory
containing the gempub will be printed on the console.

```sh
gempubify --ipfs-import book.epub
```

## Gempub viewer

*gemv* is a basic gempub viewer written with the Kivy UI library.
It can also open ebooks in the *epub* format by converting them
*on-the-fly* to the *gempub* format.

```sh
gemv
```
