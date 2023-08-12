# gemgemgem

A small Python toolkit to work with gemini and
[gempub](https://codeberg.org/oppenlab/gempub) archives.

- [gemalaya](#gemalaya): a keyboard-driven Gemini browser written in QML
- [gemv](#gemv): a small Gempub viewer
- gempubify: a command to convert *epub* ebooks to gempub archives

```sh
pip install .
```

## Gemalaya

[Download Gemalaya's latest AppImage (x86_64)](https://gitlab.com/galacteek/gemgemgem/-/releases/continuous-master/downloads/Gemalaya-latest-x86_64.AppImage)

*Gemalaya* is a keyboard-driven Gemini browser written in QML (PySide6).
Links can be navigated from the keyboard using simple key sequences.
One of the goals of this project is to focus on simplicity and readability,
for example when you hover some text, its formatting, style, font, etc ..
can change to make the paragraph more comfortable to read.
*Status: mostly a demonstration browser for now, more work needed.*

*Gemalaya* doesn't use a tab bar for now, there's just a stack layout with
pages in it, you'll see the page index on the top-left corner.

Each link in a gemini page is assigned a number. To follow a link, just type in
the number of the link on the keyboard. The link is opened after a certain
timeout.

Default keybindings (see *default_config.yaml* for all the shortcuts):

- *Ctrl+Tab*: switch between pages in the stack layout
- *Tab*: change the focus to the next element in the page
- *Ctrl+q*: quit
- *Ctrl+d*: bookmark the current page
- *Ctrl+t*: open up a new gemspace
- *Ctrl+Backspace*: go back in the history
- *o*: Toggle the target for links opened in this page (can be opened in the
    same gemspace or in a new gemspace)

Download the AppImage or install it with:

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

[Download GemV's latest AppImage (x86_64)](https://gitlab.com/galacteek/gemgemgem/-/releases/continuous-master/downloads/GemV-latest-x86_64.AppImage)

*gemv* is a basic gempub viewer written with the Kivy UI library.
It can also open ebooks in the *epub* format by converting them
*on-the-fly* to the *gempub* format.

To install and run the gempub viewer (*GemV*), use the following commands:

```sh
pip install '.[gemv]'

gemv
```

[Download GemV's latest AppImage (x86_64)](https://gitlab.com/galacteek/gemgemgem/-/releases/continuous-master/downloads/GemV-latest-x86_64.AppImage)
