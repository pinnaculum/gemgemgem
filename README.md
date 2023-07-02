# gemgemgem

A small Python toolkit to work with gemini and
[gempub](https://codeberg.org/oppenlab/gempub) archives.

```sh
pip install .
```

To install the gempub viewer (*GemV*) Kivy dependencies as well:

```sh
pip install '.[ui]'
```

## Convert an epub to gempub

To convert an ebook in the *epub* format to a *gempub* archive,
use the *gempubify* command:

```sh
gempubify book.epub

gempubify -o gembook.gpub book.epub
```

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
