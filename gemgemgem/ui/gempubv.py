import mimetypes
import os.path
import sys

from kivy.properties import ObjectProperty
from kivy.properties import StringProperty
from kivy.app import App
from kivy.uix.floatlayout import FloatLayout
from kivy.uix.popup import Popup

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


class CoverDialog(FloatLayout):
    cover_path = StringProperty()


class ImagePopup(FloatLayout):
    image_path = StringProperty()


class Viewer(FloatLayout):
    book = None
    current_toc_idx = 0

    _popup = None
    _cover_popup = None

    def book_loaded(self) -> bool:
        return self.book is not None

    def dismiss_popup(self):
        if self._popup:
            self._popup.dismiss()

    def show_cover(self):
        if self.book and self.book.m['cover']:
            cover_file = self.book.extract_item(self.book.m['cover'])
            if not cover_file:
                return

            content = CoverDialog(cover_path=str(cover_file))

            self._cover_popup = Popup(title="Book cover",
                                      content=content,
                                      size_hint=(0.8, 0.8))
            self._cover_popup.open()

    def show_image(self, path: str) -> None:
        if self.book and path:
            img_file = self.book.extract_item(path)
            if not img_file:
                return

            content = ImagePopup(image_path=str(img_file))

            self._popup = Popup(title="",
                                content=content,
                                size_hint=(0.8, 0.8))
            self._popup.open()

    def show_load(self):
        content = LoadDialog(open=self.open, close=self.dismiss_popup,
                             show_cover=self.show_cover)

        self._popup = Popup(title="Load file", content=content,
                            size_hint=(0.9, 0.9))
        self._popup.open()

    def load_page(self, path: str = None):
        doctext = ''
        doc = GmiDocument()
        page = self.book.index() if not path else self.book.read_doc(path)

        if not page:
            self.ids.page.text = f'Error loading: {path}'
            return

        for line in page.decode().split('\n'):
            doc.append(line)

        for line in doc.emit_line_objects(auto_tidy=True):
            if line.type == GmiLineType.LINK:
                doctext += f"[color=4a9ea1][size=30][ref={line.extra}]" \
                    f"{line.text}[/ref][/size][/color]\n"
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
            else:
                # Default
                doctext += line.text + "\n"

        self.ids.page.text = doctext
        self.ids.scroll_view.scroll_y = 1

    def load_from_toc_index(self, idx: int = 1):
        item = self.book.toc.get(idx + 1)
        if item:
            self.load_page(item[0])
            self.current_toc_idx = idx

    def link_clicked(self, link):
        toc = self.book.toc
        fbase, fext = os.path.splitext(os.path.basename(link))
        mtype = mimetypes.guess_type(os.path.basename(link))[0]
        mtypec = mtype.split('/')[0] if mtype else None

        if mtypec == 'image':
            return self.show_image(link)

        for i, data in enumerate(ListIteratorForward(toc.first)):
            if data[0] == link:
                self.load_from_toc_index(i)
                break

    def open(self, path: str, filename: str) -> bool:
        self.ids.toc_button.disabled = True

        mtype = mimetypes.guess_type(filename)[0]
        fbase, fext = os.path.splitext(filename)
        p = Path(path).joinpath(filename)

        if not p.is_file():
            return False

        if mtype == 'application/epub+zip':
            gp, dst = gempubify.gempubify_file(p)
            self.book = gp
        elif mtype is None or fext in ['.gpub', '.gempub']:
            with gempub.load(p) as gp:
                self.book = gp

        self.current_toc_idx = 0

        self.load_page()

        self.ids.title.text = self.book.m['title']
        self.ids.toc_button.disabled = False

        return True

    def show_toc(self) -> None:
        self.load_page()
        self.current_toc_idx = 0

    def toc_next(self):
        if self.book and self.current_toc_idx >= 0:
            self.load_from_toc_index(self.current_toc_idx + 1)

    def toc_prev(self):
        if not self.book:
            return

        if self.current_toc_idx >= 2:
            self.load_from_toc_index(self.current_toc_idx - 1)
        else:
            self.show_toc()

    def quit(self):
        sys.exit(0)


class ViewerApp(App):
    def build(self):
        return Viewer()


if __name__ == '__main__':
    ViewerApp().run()
