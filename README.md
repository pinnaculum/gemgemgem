# gemgemgem

*gemgemgem* (can be heard as *"J'aime j'aime j'aime"*, meaning
*"I love i love i love"* in French) is a collection of Gemini apps and tools
written in Python. It includes:

- [gemalaya](#gemalaya): a keyboard-driven Gemini browser written in QML
- [gemv](#gemv): a small [Gempub](https://codeberg.org/oppenlab/gempub) viewer
- gempubify: a command to convert *epub* ebooks to gempub archives

## Gemalaya

[Download Gemalaya's latest AppImage (x86_64)](https://gitlab.com/galacteek/gemgemgem/-/releases/continuous-master/downloads/Gemalaya-latest-x86_64.AppImage)

**Be sure to have all the xcb libraries installed before running the AppImage**
(run with *QT_DEBUG_PLUGINS=1* if you get an error the xcb plugin failing to
load)

*Gemalaya* is a keyboard-driven Gemini browser written in QML (PySide6).
Links can be navigated from the keyboard using simple key sequences.
One of the goals of this project is to focus on simplicity and also readability,
for example when you hover some text, its formatting, style, font, etc ..
can change to make the paragraph more comfortable to read.
*Status: mostly a demonstration browser for now, more work needed.*

*Gemalaya* doesn't use a tab bar for now, there's just a stack layout with
pages in it, you'll see the page index on the top-left corner. The browser
will automatically generate a certificate, if you want to use an already
generated certificate, copy it as *$HOME/.config/gemalaya/client.{crt,key}*.

Each link in a gemini page is assigned a number. To follow a link, just type in
the number of the link on the keyboard. The link is opened after a certain
timeout.

*Gemalaya* supports the automatic proxying of web (http/https) content
by running an instance of [levior](https://gitlab.com/cipres/levior).
When *levior* is running, web URLs referenced in gemtext documents
are rewritten to be served through the http-to-gemini proxy.

Default keyboard shortcuts (see *default_config.yaml* for all the shortcuts):

- *Tab*: change the focus to the next element in the page
- *Ctrl+d*: bookmark the current page
- *Ctrl+t*: open up a new gemspace
- *Ctrl+Backspace*: go back in the history
- *Ctrl+o*: Change the target for links opened in this page (the
    target indicator is shown right next to the URL):
  - H (yellow): open here (the default)
  - T (blue): open in a new tab/gemspace
  - W (red): open in a new window
  (can be opened in the same gemspace or in a new gemspace)
- *Ctrl+b*: go to the previous gemspace
- *Ctrl+n*: go to the next gemspace
- *Ctrl+Tab*: cycle between gemspaces in the stack layout
- *Ctrl+y*: cycle between the available themes
- *Ctrl++*: Increase the font size (and save the settings)
- *Ctrl+-*: Decrease the font size (and save the settings)
- *Ctrl+q*: quit

You can write your own theme, it should be a YAML file with the following path
(on Linux), *theme_name* being the name of your theme. Look in the *gemalaya/themes*
directory for an example.

> $HOME/.config/gemalaya/themes/theme_name/theme_name.yaml

Then set the *ui.theme* config setting in the main config file which is stored
in:

> $HOME/.config/gemalaya/config.yaml

### Install

Download the AppImage or install it with:
b

```sh
pip install '.[gemalaya]'
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
