import functools
from collections import deque

from PySide6.QtCore import QObject
from PySide6.QtCore import QJsonValue
from PySide6.QtCore import Property
from PySide6.QtCore import Slot
from PySide6.QtCore import Signal
from PySide6.QtCore import QByteArray
from PySide6.QtWidgets import QApplication

import os
import os.path
import re
import tempfile
import traceback

from pathlib import Path
from yarl import URL
from md2gemini import md2gemini
from trimgmi import Document as GmiDocument
from trimgmi import LineType as GmiLineType

from gemgemgem import feed2gem
from .qt import tSlot

from cachetools import TTLCache
import ignition
import rst2gemtext


class GeminiInterface(QObject):
    srvResponse = Signal(dict, arguments=['resp'])
    srvError = Signal(str, arguments=['message'])

    fileDownloaded = Signal(dict, arguments=['resp'])
    fileDownloadError = Signal(str, arguments=['error'])

    dlqSizeChanged = Signal(int, arguments=['qsize'])

    def __init__(self, parent=None):
        super().__init__(parent)

        self.app = QApplication.instance()
        self._dcache = TTLCache(16, 20)
        self._dlq = deque([])
        self._temp_files = []

        self.certp = self.app.default_certp
        self.keyp = self.app.default_keyp
        self.destroyed.connect(functools.partial(self.onDestroyed))

    def onDestroyed(self):
        for tmpf in self._temp_files:
            try:
                os.unlink(tmpf)
            except Exception:
                continue

    @Property(int, notify=dlqSizeChanged)
    def dlqsize(self):
        return len(self._dlq)

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

    def writeRspDataToFile(self, response, dstPath: Path):
        try:
            if dstPath.is_file():
                for x in range(0, 64):
                    p = Path(f'{dstPath}.{x}')
                    if not p.exists():
                        dstPath = p
                        break

            assert not dstPath.exists()

            with open(dstPath, 'wb') as fd:
                fd.write(response.raw_body)

            return True
        except Exception:
            return False

    def downloadPathForUrl(self, dlRootPath: str, requ: URL) -> Path:
        """
        Return the download path for a gemini URL
        """
        try:
            dstPath = Path(dlRootPath).joinpath(
                requ.host).joinpath(requ.path.lstrip('/'))
            dstPath.parent.mkdir(parents=True, exist_ok=True)
            return dstPath
        except Exception:
            traceback.print_exc()

    @tSlot(str, QJsonValue, sigSuccess="fileDownloaded")
    def downloadToFile(self,
                       href: str,
                       options: QJsonValue):
        opts = options.toVariant()
        dlRootPath = opts.get('downloadsPath')

        try:
            requ = URL(href)
            assert requ.scheme == 'gemini'

            self._dlq.appendleft(str(requ))
            self.dlqSizeChanged.emit(len(self._dlq))

            response = ignition.request(
                str(requ),
                ca_cert=(self.certp, self.keyp),
                timeout=opts.get('timeout', 60)
            )

            data = response.raw_body

            if not response.is_a(ignition.SuccessResponse):
                raise Exception(f'Download error for: {href}')

            if dlRootPath:
                dstPath = self.downloadPathForUrl(dlRootPath, requ)
                assert dstPath
                assert self.writeRspDataToFile(response, dstPath)
            else:
                with tempfile.NamedTemporaryFile(mode='wb',
                                                 delete=False) as file:
                    file.write(
                        data if isinstance(data, bytes) else data.encode())

                self._temp_files.append(file.name)
                dstPath = Path(file.name)

            self._dlq.remove(str(requ))
            self.dlqSizeChanged.emit(len(self._dlq))

            return {
                'url': href,
                'meta': response.meta,
                'path': str(dstPath)
            }
        except Exception:
            traceback.print_exc()
            raise

    @Slot(str, str, result=str)
    def buildUrl(self,
                 href: str,
                 baseUrl: str):
        ref = URL(href)
        base = URL(baseUrl)

        if base.scheme and base.scheme != 'gemini' and \
           not ref.scheme and ref.path:
            return str(base.join(ref))

        return ignition.url(href, baseUrl)

    @tSlot(str, str, QJsonValue, sigSuccess="srvResponse")
    def geminiModelize(self,
                       href: str,
                       referer: str,
                       options: QJsonValue):
        linkno = 0
        model = []
        doc = GmiDocument()
        title = None
        opts = options.toVariant()
        dlRootPath = opts.get('downloadsPath')
        linksMode = opts.get('linksMode', 'list')

        try:
            extra = {}
            requ = URL(href)

            if requ.scheme in ['http', 'https', 'ipfs', 'ipns']:
                extra['http_proxy'] = ('localhost', 1965)

            if requ.scheme == 'titan':
                filePath = opts.get('titanUploadPath')
                assert filePath is not None

                fp = Path(filePath)
                assert fp.is_file()

                extra['titan_data'] = fp
                extra['titan_token'] = opts.get('titanToken', fp.name)

            if href in self._dcache:
                return self._dcache[href]

            response = ignition.request(
                str(requ),
                ca_cert=(self.certp, self.keyp),
                timeout=opts.get('timeout', 60),
                **extra
            )
            assert response

            rspData = response.data()

            ctype = response.meta.split(';')[0] if \
                response.meta else None

            if response.is_a(ignition.ErrorResponse) or \
                response.is_a(ignition.TempFailureResponse) or \
                    response.is_a(ignition.PermFailureResponse):
                return {
                    'url': href,
                    'rsptype': 'error',
                    'message': rspData
                }

            elif response.is_a(ignition.InputResponse):
                rsptype = 'input'
            elif response.is_a(ignition.ClientCertRequiredResponse):
                rsptype = 'certrequired'
            elif response.is_a(ignition.RedirectResponse):
                rsptype = 'redirect'

                redirUrl = URL(rspData)

                if not redirUrl.is_absolute():
                    if redirUrl.path.startswith('/'):
                        redirUrl = URL.build(
                            scheme='gemini',
                            host=requ.host,
                            path=rspData
                        )
                    else:
                        redirUrl = URL(f'{requ}/{rspData}')

                return {
                    'url': href,
                    'rsptype': rsptype,
                    'redirectUrl': str(redirUrl)
                }
            else:
                rsptype = 'data'

            if rsptype == 'input':
                return {
                    'url': href,
                    'rsptype': rsptype,
                    'prompt': rspData,
                    'model': model,
                }

            if ctype in ['application/xml',
                         'application/x-rss+xml',
                         'application/rss+xml',
                         'text/xml',
                         'application/atom+xml']:
                # Atom or RSS feed: try to convert to tinylog
                gemt = feed2gem.feed2tinylog(rspData)
                if gemt:
                    rspData = gemt
            elif ctype == 'text/markdown':
                # Markdown content. Convert to gemtext with md2gemini

                rspData = md2gemini(
                    rspData,
                    links='paragraph',
                    indent="  ",
                    checklist=False,
                    strip_html=True,
                    plain=True
                )
            elif ctype in ['text/plain',
                           'text/x-rst'] and \
                    requ.name.lower().endswith('.rst'):
                # Proably restructured text, convert it to gemtext
                try:
                    gemt = rst2gemtext.convert(rspData)
                except Exception:
                    pass
                else:
                    rspData = gemt
            elif ctype != 'text/gemini':
                if not dlRootPath:
                    dlRootPath = tempfile.mkdtemp()

                dstPath = self.downloadPathForUrl(dlRootPath, requ)
                assert dstPath

                if self.writeRspDataToFile(response, dstPath):
                    return {
                        'url': href,
                        'rsptype': 'raw',
                        'data': rspData,
                        'downloadPath': str(dstPath),
                        'meta': response.meta,
                        'contentType': ctype
                    }
                else:
                    raise Exception(f'Could not download to path {dstPath}')

            for line in rspData.split('\n'):
                doc.append(line)

            hrefPrev = None
            pf: list = []
            quoteb: list = []
            linksGroup: list = []

            for line in doc.emit_line_objects(auto_tidy=True):
                if line.type != GmiLineType.QUOTE and quoteb:
                    # Flush the quote buffer and reset it
                    model.append({
                        'type': 'quote',
                        'text': '\n'.join(quoteb)
                    })
                    quoteb = []

                if line.type != GmiLineType.LINK and linksGroup and \
                        linksMode == 'group':
                    # Flush the links group
                    model.append({
                        'type': 'linksgroup',
                        'links': linksGroup
                    })
                    linksGroup = []

                if line.type == GmiLineType.LINK:
                    # Compute keyboard sequence shortcut

                    alpham = re.match(r'^.*?([\w0-9]+)', line.text)

                    linke = {
                        'type': 'link',
                        'href': line.extra,
                        'hrefPrev': hrefPrev,
                        'title': line.text if line.text else line.extra,
                        'alphan': alpham.group(1) if alpham else None
                    }

                    if linksMode == 'group':
                        linksGroup.append(linke)
                    else:
                        model.append(linke)

                    hrefPrev = line.extra
                    linkno += 1
                elif line.type == GmiLineType.REGULAR:
                    model.append({
                        'type': 'regular',
                        'text': line.text,
                        'title': line.text if line.text else line.extra
                    })
                elif line.type == GmiLineType.BLANK:
                    model.append({
                        'type': 'blank'
                    })
                elif line.type == GmiLineType.QUOTE and line.text:
                    quoteb.append(line.text)
                elif line.type == GmiLineType.LIST_ITEM:
                    model.append({
                        'type': 'listitem',
                        'text': line.text
                    })
                elif line.type in [GmiLineType.HEADING1,
                                   GmiLineType.HEADING2,
                                   GmiLineType.HEADING3]:
                    if line.type == GmiLineType.HEADING1:
                        hsize = 'h1'
                    elif line.type == GmiLineType.HEADING2:
                        hsize = 'h2'
                    elif line.type == GmiLineType.HEADING3:
                        hsize = 'h3'

                    if title is None:
                        title = line.text

                    model.append({
                        'type': 'heading',
                        'hsize': hsize,
                        'text': line.text
                    })
                elif line.type == GmiLineType.PREFORMAT_START:
                    pf = []
                elif line.type == GmiLineType.PREFORMAT_LINE and line.text:
                    pf.append(line.text)
                elif line.type == GmiLineType.PREFORMAT_END:
                    if pf:
                        model.append({
                            'type': 'preformatted',
                            'text': '\n'.join(pf)
                        })

            if linksGroup:
                model.append({
                    'type': 'linksgroup',
                    'links': linksGroup
                })

            resp = {
                'url': href,
                'rsptype': rsptype,
                'model': model,
                'title': title
            }

            self._dcache[href] = resp

            return resp
        except Exception:
            traceback.print_exc()

            self.srvError.emit(traceback.format_exc())
