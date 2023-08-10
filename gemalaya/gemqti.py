import tempfile
import traceback
import string

from pathlib import Path
from yarl import URL
from omegaconf import OmegaConf

import ignition

from PySide6.QtCore import QObject
from PySide6.QtCore import QJsonValue
from PySide6.QtCore import Slot
from PySide6.QtCore import Signal
from PySide6.QtCore import QByteArray
from PySide6.QtWidgets import QApplication

from trimgmi import Document as GmiDocument
from trimgmi import LineType as GmiLineType

from cachetools import TTLCache
import functools
import concurrent.futures


threadpool = concurrent.futures.ThreadPoolExecutor(max_workers=16)


def tSlot(*args, **kws):
    def got_result(sig, future):
        try:
            sig.emit(future.result())
        except Exception:
            pass

    def outer_decorator(fn):
        @Slot(*args)
        @functools.wraps(fn)
        def wrapper(*args, **kwargs):
            emits = kws.get('emitWith')
            sig = getattr(args[0], emits)

            f = threadpool.submit(fn, *args)
            f.add_done_callback(functools.partial(got_result, sig))

        return wrapper
    return outer_decorator


class GeminiInterface(QObject):
    srvResponse = Signal(dict, arguments=['resp'])
    srvError = Signal(str, arguments=['message'])

    def __init__(self, parent=None):
        super().__init__(parent)

        self.app = QApplication.instance()
        self._dcache = TTLCache(16, 60)

        self.certp = self.app.default_certp
        self.keyp = self.app.default_keyp

    @Slot(str, QJsonValue, result="QVariant")
    def getRaw(self,
               href: str,
               options: QJsonValue):
        try:
            requ = URL(href)
            response = ignition.request(
                str(requ),
                ca_cert=(self.certp, self.keyp),
                timeout=5
            )
            data = response.data()
            return QByteArray(bytes(data))
        except Exception:
            traceback.print_exc()
            return None

    @Slot(str, QJsonValue, result=str)
    def downloadToFile(self,
                       href: str,
                       options: QJsonValue):
        try:
            requ = URL(href)
            response = ignition.request(
                str(requ),
                ca_cert=(self.certp, self.keyp)
            )

            with tempfile.NamedTemporaryFile(mode='wb',
                                             delete=False) as file:
                file.write(response.data())

            return file.name
        except Exception:
            traceback.print_exc()

    @Slot(str, str, result=str)
    def buildUrl(self,
                 path: str,
                 baseUrl: str):
        return ignition.url(path, baseUrl)

    @tSlot(str, str, QJsonValue, emitWith="srvResponse")
    def geminiModelize(self,
                       href: str,
                       referer: str,
                       options: QJsonValue):
        linkno = 0
        model = []
        doc = GmiDocument()

        try:
            requ = URL(href)

            inc = self._dcache.get(href)
            if inc and 0:
                return inc

            response = ignition.request(
                str(requ),
                ca_cert=(self.certp, self.keyp),
                timeout=10
            )
            assert response
            gemText = response.data()

            if response.is_a(ignition.InputResponse):
                rsptype = 'input'
            elif response.is_a(ignition.RedirectResponse):
                rsptype = 'redirect'
            elif response.is_a(ignition.TempFailureResponse) or \
                    response.is_a(ignition.PermFailureResponse) or \
                    response.is_a(ignition.ErrorResponse):
                rsptype = 'error'
            else:
                rsptype = 'data'

            if rsptype == 'input':
                return {
                    'url': href,
                    'rsptype': rsptype,
                    'prompt': gemText,
                    'model': model,
                }

            for line in gemText.split('\n'):
                doc.append(line)

            hrefPrev = None
            for line in doc.emit_line_objects(auto_tidy=True):
                if line.type == GmiLineType.LINK:
                    # Compute keyboard sequence shortcut

                    lsec, rem = divmod(linkno, len(string.ascii_letters))

                    if lsec == 0:
                        letter = string.ascii_letters[linkno]

                        if letter.islower():
                            keyseq = letter
                        else:
                            keyseq = f'Shift+{letter}'

                    elif lsec in range(1, 3):
                        letter = string.ascii_letters[rem]
                        mod = 'Ctrl' if lsec == 1 else 'Alt'

                        keyseq = f'{mod}+{letter}'

                    model.append({
                        'type': 'link',
                        'href': line.extra,
                        'hrefPrev': hrefPrev,
                        'keyseq': keyseq,
                        'title': line.text if line.text else line.extra
                    })
                    hrefPrev = line.extra
                    linkno += 1
                elif line.type == GmiLineType.REGULAR:
                    model.append({
                        'type': 'regular',
                        'text': line.text,
                        'title': line.text if line.text else line.extra
                    })
                elif line.type == GmiLineType.QUOTE:
                    model.append({
                        'type': 'quote',
                        'text': line.text,
                        'title': line.text if line.text else line.extra
                    })
                elif line.type == GmiLineType.LIST_ITEM:
                    model.append({
                        'type': 'listitem',
                        'text': line.text
                    })
                elif line.type in [GmiLineType.HEADING1,
                                   GmiLineType.HEADING2,
                                   GmiLineType.HEADING3]:
                    model.append({
                        'type': 'heading',
                        'text': line.text
                    })

            resp = {
                'url': href,
                'rsptype': rsptype,
                'model': model,
                'title': None
            }

            if href not in self._dcache:
                self._dcache[href] = resp

            return resp
        except Exception:
            traceback.print_exc()

            self.srvError.emit('Error')


class GemalayaInterface(QObject):
    def __init__(self, cfg_path: Path, config, parent=None):
        super().__init__(parent)

        self.config = config
        self.cfg_path = cfg_path

    def __save_config(self):
        OmegaConf.save(config=self.config, f=str(self.cfg_path))

    @Slot(result=dict)
    def getConfig(self):
        return OmegaConf.to_container(self.config)

    @Slot(str, QJsonValue, result=bool)
    def set(self, attr: str, value: QJsonValue):
        try:
            setattr(self.config, attr, value.toVariant())
        except AttributeError:
            traceback.print_exc()
            return False
        except Exception:
            traceback.print_exc()
            return False
        else:
            self.__save_config()
            return True
