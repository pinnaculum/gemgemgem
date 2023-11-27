# gemgemgem

*gemgemgem* (can be heard as *"J'aime j'aime j'aime"*, meaning
*"I love i love i love"* in French) is a collection of
[Gemini](https://geminiprotocol.net) apps and tools
written in Python. It includes:

- [gemalaya](https://gemalaya.gitlab.io): a keyboard-driven Gemini browser written in QML ([Download AppImage](https://gitlab.com/cipres/gemgemgem/-/releases/continuous-master/downloads/Gemalaya-latest-x86_64.AppImage))
- [gemv](#gemv): a small [Gempub](https://codeberg.org/oppenlab/gempub) viewer
- gempubify: a program to convert *epub* ebooks to gempub archives

## Gemalaya

![bbs](https://gitlab.com/cipres/gemgemgem/-/raw/master/media/screenshots/gemalaya-bbs-vim-small.png))

[Download Gemalaya's latest AppImage (x86_64)](https://gitlab.com/cipres/gemgemgem/-/releases/continuous-master/downloads/Gemalaya-latest-x86_64.AppImage) **Be sure to have all the xcb libraries installed before running the AppImage** (run with *QT_DEBUG_PLUGINS=1* if you get an error the xcb plugin failing to
load)

*Gemalaya* is a keyboard-driven Gemini browser written in QML (PySide6).
Links can be navigated from the keyboard using simple key sequences.
Each link in a gemini page is assigned a number. To follow a link, just type in
the number of the link on the keyboard.

*Gemalaya* supports the automatic proxying of web (http/https) and dweb content
by running an instance of [levior](https://gitlab.com/cipres/levior).
When *levior* is running, web URLs referenced in gemtext documents
are served through the web-to-gemini proxy. It also supports
[Text-to-speech](https://gemalaya.gitlab.io/##text-to-speech).

Please visit [gemalaya's website](https://gemalaya.gitlab.io) for more!

### Install

Download the AppImage or install it with:

```sh
pip install '.[gemalaya,gemalaya-http-proxy]'
python setup.py build_gemalaya install
```

Start the browser by running the *gemalaya* command.

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

See [the manual's project file](https://gitlab.com/cipres/gemgemgem/-/blob/master/docs/gemv/manual/manual.yaml) for an example.

If you have access to an IPFS (kubo) daemon and want to import the
gempub file to IPFS, use *--ipfs-import*. The CID of the directory
containing the gempub will be printed on the console.

```sh
gempubify --ipfs-import book.epub
```

## Gemv

[Download GemV's latest AppImage (x86_64)](https://gitlab.com/cipres/gemgemgem/-/releases/continuous-master/downloads/GemV-latest-x86_64.AppImage)

*gemv* is a basic gempub viewer written with the Kivy UI library.
It can also open ebooks in the *epub* format by converting them
*on-the-fly* to the *gempub* format.

To install and run the gempub viewer (*GemV*), use the following commands:

```sh
pip install '.[gemv]'

gemv
```
