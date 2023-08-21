import mimetypes
import os.path
import sys
import webbrowser
import ipfshttpclient
from collections import deque

from yarl import URL
from typing import Union
from urllib.parse import urldefrag

from kivy.properties import ObjectProperty
from kivy.properties import StringProperty
from kivy.app import App
from kivy.uix.floatlayout import FloatLayout
from kivy.uix.popup import Popup
from kivy.core.window import Window

from pathlib import Path
from DoubleLinkedList.DLinked import ListIteratorForward

from trimgmi import Document as GmiDocument
from trimgmi import LineType as GmiLineType

from gemgemgem import gempub
from gemgemgem import gempubify


class LoadDialog(FloatLayout):
    load = ObjectProperty()
    open = ObjectProperty()
    show_cover = ObjectProperty()
    close = ObjectProperty()

    def get_default_path(self):
        self.path = os.path.expanduser("~")
        return self.path


class LoadFromURLDialog(FloatLayout):
    load = ObjectProperty()
    open = ObjectProperty()
    show_cover = ObjectProperty()
    close = ObjectProperty()


class CoverDialog(FloatLayout):
    cover_path = StringProperty()


class ImagePopup(FloatLayout):
    image_path = StringProperty()


class ViewerConfig:
    pass


class Viewer(FloatLayout):
    def __init__(self, *args, **kw):
        super().__init__(*args, **kw)

        self.book = None
        self._lib_path: Path = None
        self._current_toc_idx: int = 0
        self._current_doc_path: Path = None
        self._books_url_hist: deque = deque([], maxlen=16)
        self._popup = None

        self._keyboard = Window.request_keyboard(None, self)
        self._keyboard.bind(on_key_down=self.on_keyb_press)

        self.enable_ctrl_buttons(False)

    @property
    def libp(self):
        return self._lib_path

    @property
    def bhist(self):
        return self._books_url_hist

    def set_library_path(self, lpath: Path):
        if lpath.is_dir():
            self._lib_path = lpath

    def on_keyb_press(self, keyboard, keycode, text, modifiers) -> None:
        """
        Handle keypress events
        """

        kc = keycode[1]

        if 'ctrl' in modifiers:
            # Ctrl +/- for larger/smaller font
            if kc == '+':
                self.ids.page.font_size += 2
            elif kc == '-':
                self.ids.page.font_size -= 2
            elif kc == 'o':
                self.show_fileload_dialog()
            elif kc == 'q':
                self.quit()
            elif kc == 'right':
                self.toc_next()
            elif kc == 'left':
                self.toc_prev()
        else:
            # Handle pageup/pagedown
            dist = self.ids.scroll_view.convert_distance_to_scroll(0, 140)

            if kc == 'pageup' and self.ids.scroll_view.scroll_y < 1:
                self.ids.scroll_view.scroll_y += dist[1]
            elif kc == 'up' and self.ids.scroll_view.scroll_y < 1:
                self.ids.scroll_view.scroll_y += dist[1] / 2
            elif kc == 'pagedown' and self.ids.scroll_view.scroll_y > 0:
                self.ids.scroll_view.scroll_y -= dist[1]
            elif kc == 'down' and self.ids.scroll_view.scroll_y > 0:
                self.ids.scroll_view.scroll_y -= dist[1] / 2
            elif kc == 'end':
                self.ids.scroll_view.scroll_y = 0
            elif kc == 'home':
                self.ids.scroll_view.scroll_y = 1

    def book_loaded(self) -> bool:
        return self.book is not None

    def dismiss_popup(self):
        if self._popup:
            self._popup.dismiss()

    def history_back(self):
        if len(self.bhist) > 1:
            self.bhist.popleft()

            loc = self.bhist[0]
            if isinstance(loc, Path):
                self.open(loc)
            elif isinstance(loc, URL):
                self.open_from_url(loc)

    def show_cover(self):
        if self.book and self.book.m['cover']:
            cover_file = self.book.extract_item(self.book.m['cover'])
            if not cover_file:
                return

            content = CoverDialog(cover_path=str(cover_file))

            Popup(title="Book cover",
                  content=content,
                  size_hint=(0.8, 0.8)).open()

    def show_image(self, path: str) -> None:
        if self.book and path:
            img_file = self.book.extract_item(path)
            if not img_file:
                return

            content = ImagePopup(image_path=str(img_file))

            Popup(title="",
                  content=content,
                  size_hint=(0.8, 0.8)).open()

    def show_fileload_dialog(self):
        content = LoadDialog(open=self.open_from_dir,
                             show_cover=self.show_cover)

        popup = Popup(title="Load file", content=content,
                            size_hint=(0.9, 0.9))
        content.close = popup.dismiss
        popup.open()

    def show_urlload_dialog(self):
        content = LoadFromURLDialog(
            open=self.open_from_url,
            show_cover=self.show_cover
        )

        popup = Popup(title="Load gempub from URL",
                      content=content,
                      size_hint=(0.8, 0.4))
        content.close = popup.dismiss
        popup.open()

    def load_page(self, page_path: str = None, title: str = None) -> bool:
        # Defragment first
        path = urldefrag(page_path).url

        self.ids.chapter.text = ''

        doctext = ''
        doc = GmiDocument()
        page = self.book.index() if not path else self.book.read_doc(path)

        if not page:
            self.ids.page.text = f'Error loading: {path}'
            return False

        for line in page.decode().split('\n'):
            doc.append(line)

        for lco, line in enumerate(doc.emit_line_objects(auto_tidy=True)):
            if line.type == GmiLineType.LINK:
                link_text = line.text if line.text else line.extra
                doctext += f'[color=4a9ea1][size=20][ref={line.extra}]' \
                    f"{link_text}[/ref][/size][/color]\n"
            elif line.type == GmiLineType.PREFORMAT_LINE:
                doctext += line.text + "\n"
            elif line.type == GmiLineType.HEADING1:
                doctext += \
                    f"[color=6495ed][size=32][b]{line.text}[/b]" \
                    "[/size][/color]\n"
            elif line.type == GmiLineType.HEADING2:
                doctext += \
                    f"[color=6495ed][size=28][b]{line.text}[/b]" \
                    "[/size][/color]\n"
            elif line.type == GmiLineType.HEADING3:
                doctext += \
                    f"[color=6495ed][size=26][b]{line.text}[/b]" \
                    "[/size][/color]\n"
            elif line.type == GmiLineType.QUOTE:
                # TODO
                doctext += f"[i]{line.text}[/i]\n"
            elif line.type == GmiLineType.LIST_ITEM:
                # kivy's Label doesn't support [li] :/
                doctext += f"- {line.text}\n"
            elif line.type == GmiLineType.REGULAR:
                doctext += line.text + "\n"
            elif line.type == GmiLineType.BLANK:
                doctext += "\n"

        self.ids.page.text = doctext
        self.ids.page.texture_update()
        self.ids.scroll_view.scroll_y = 1

        if title:
            self.ids.chapter.text = title

        self._current_doc_path = Path(path) if path else None
        return True

    def load_from_toc_index(self, idx: int = 1):
        item = self.book.toc.get(idx + 1)
        if item:
            self.load_page(item[0], title=item[1])
            self._current_toc_idx = idx

    def link_clicked(self, link: str) -> None:
        url = URL(link)
        if url.scheme in ['http', 'https', 'ftp']:
            return webbrowser.open(link)

        fbase, fext = os.path.splitext(os.path.basename(link))

        if fext == '.gpub':
            # Clicked on a gempub
            if url.scheme in ['gemini',
                              'ipfs',
                              'https']:
                return self.open_from_url(url)
            elif not url.scheme:
                # A gempub inside the gempub we're currently viewing

                if self._current_doc_path:
                    p = self._current_doc_path.parent.joinpath(url.path)
                else:
                    p = Path(url.path)

                exgemp = self.book.extract_item(str(p))

                if exgemp:
                    self.open(exgemp)
                else:
                    # TODO: show some error
                    return

        mtype = mimetypes.guess_type(os.path.basename(link))[0]
        mtypec = mtype.split('/')[0] if mtype else None

        if mtypec == 'image':
            return self.show_image(link)

        for i, data in enumerate(ListIteratorForward(self.book.toc.first)):
            if data[0] == link:
                self.load_from_toc_index(i)
                break

    def enable_ctrl_buttons(self, enabled: bool = True) -> None:
        self.ids.toc_button.disabled = not enabled
        self.ids.next_button.disabled = not enabled
        self.ids.prev_button.disabled = not enabled
        self.ids.history_back_button.disabled = not len(self.bhist) > 1

    def set_book(self, book) -> bool:
        self.book = book
        self._current_toc_idx = 0
        self._current_doc_path = None
        self.load_page()
        self.ids.title.text = self.book.m['title']

        if self.book.location and self.book.location not in self.bhist:
            self._books_url_hist.appendleft(self.book.location)

        self.enable_ctrl_buttons(True)
        return True

    def open(self, filepath: Union[Path, str]) -> bool:
        fp = filepath if isinstance(filepath, Path) else Path(filepath)

        if fp.is_file():
            return self.open_from_dir(str(fp.parent), fp.name)

    def open_from_dir(self, path: str, filename: str) -> bool:
        self.enable_ctrl_buttons(False)

        mtype = mimetypes.guess_type(filename)[0]
        fbase, fext = os.path.splitext(filename)
        p = Path(path).joinpath(filename)

        if not p.is_file():
            return False

        print(f'{p}: fext: {fext}, mimetype is: {mtype}')

        if fext.lower() in ['.epub',
                            '.epub3'] or mtype == 'application/epub+zip':
            gp, dst = gempubify.gempubify_file(p)
            if gp:
                return self.set_book(gp)
        elif mtype is None or fext.lower() in ['.gpub', '.gempub']:
            with gempub.load(p) as gp:
                return self.set_book(gp)

        return False

    def open_from_url(self, url_arg: Union[URL, str]) -> bool:
        ipfsc = ipfshttpclient.Client()
        url = url_arg if isinstance(url_arg, URL) else URL(url_arg)

        try:
            gp = gempub.get(url, ipfs_client=ipfsc)
            assert gp

            self.set_book(gp)
        except Exception:
            return False
        else:
            return True

    def open_from_lib(self, filename: str) -> bool:
        if not self.libp:
            return

        ep = self.libp.joinpath(filename)
        if ep.is_file():
            self.open_from_dir(str(self.libp), filename)

    def show_toc(self) -> None:
        self.load_page()
        self._current_toc_idx = 0

    def toc_next(self):
        if self.book and self._current_toc_idx >= 0:
            self.load_from_toc_index(self._current_toc_idx + 1)

    def toc_prev(self):
        if not self.book:
            return

        if self._current_toc_idx >= 2:
            self.load_from_toc_index(self._current_toc_idx - 1)
        else:
            self.show_toc()

    def quit(self):
        sys.exit(0)


class ViewerApp(App):
    def __init__(self, args):
        super().__init__()

        self.args = args

    def build(self):
        v = Viewer()

        if self.args.libpath:
            v.set_library_path(Path(self.args.libpath))

        if self.args.ebook:
            v.open(Path(self.args.ebook))

        if not self.args.ebook and v.libp:
            # Open manual if no book specified
            v.open_from_lib('gemv_manual.gpub')

        return v


if __name__ == '__main__':
    ViewerApp().run()
