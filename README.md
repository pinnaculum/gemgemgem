# gemgemgem

A small Python toolkit to work with gemini and
[gempub](https://codeberg.org/oppenlab/gempub) archives.

- [gemalaya](#gemalaya): a keyboard-driven Gemini browser written in QML
- [gemv](#gemv): a small Gempub viewer
- gempubify: a command to convert *epub* ebooks to gempub archives

```sh
pip install .
```

[Download GemV's latest AppImage (x86_64)](https://gitlab.com/galacteek/gemgemgem/-/releases/continuous-master/downloads/GemV-latest-x86_64.AppImage)

## Gemalaya

*Gemalaya* is a keyboard-driven Gemini browser written in QML (PySide6).
Links can be navigated from the keyboard using simple key sequences.
One of the goals of this project is to focus on text readibility,
for example when you hover some text, its formatting, style, font, etc ..
will change to make the paragraph more comfortable to read.
*Status: mostly a demonstration browser for now, more work needed.*

Install it with:

```sh
pip install '.[gemalaya]'
python setup.py build_gemalaya install
```

Run the browser by running the *gemalaya* command.

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

## Gemv

*gemv* is a basic gempub viewer written with the Kivy UI library.
It can also open ebooks in the *epub* format by converting them
*on-the-fly* to the *gempub* format.

To install and run the gempub viewer (*GemV*), use the following commands:

```sh
pip install '.[gemv]'

gemv
```

[Download GemV's latest AppImage (x86_64)](https://gitlab.com/galacteek/gemgemgem/-/releases/continuous-master/downloads/GemV-latest-x86_64.AppImage)
