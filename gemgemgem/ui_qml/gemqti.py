import tempfile
import traceback

from pathlib import Path
from yarl import URL
from omegaconf import OmegaConf

import ignition

from PySide6.QtCore import QObject
from PySide6.QtCore import QJsonValue
from PySide6.QtCore import Slot
from PySide6.QtCore import QByteArray

from trimgmi import Document as GmiDocument
from trimgmi import LineType as GmiLineType


class GeminiInterface(QObject):
    def __init__(self, certs: tuple, parent=None):
        super().__init__(parent)

        self.certp, self.keyp = certs

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

    @Slot(str, str, QJsonValue, result=dict)
    def geminiModelize(self,
                       href: str,
                       referer: str,
                       options: QJsonValue):
        model = []
        doc = GmiDocument()

        try:
            requ = URL(href)

            response = ignition.request(
                str(requ),
                ca_cert=(self.certp, self.keyp),
                timeout=10
            )
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
                    'rsptype': rsptype,
                    'prompt': gemText,
                    'model': model,
                }

            for line in gemText.split('\n'):
                doc.append(line)

            hrefPrev = None
            for line in doc.emit_line_objects(auto_tidy=True):
                if line.type == GmiLineType.LINK:
                    model.append({
                        'type': 'link',
                        'href': line.extra,
                        'hrefPrev': hrefPrev,
                        'title': line.text if line.text else line.extra
                    })
                    hrefPrev = line.extra
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

            return {
                'rsptype': rsptype,
                'model': model,
                'title': None
            }
        except Exception:
            traceback.print_exc()


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
