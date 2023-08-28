import json
import mimetypes
import os
import os.path
import pkg_resources
import platform
import tempfile
import traceback
import signal
import subprocess
import webbrowser

from collections import deque
from pathlib import Path
from yarl import URL
from omegaconf import OmegaConf

import ignition

from PySide6.QtCore import QDir
from PySide6.QtCore import QFile
from PySide6.QtCore import QIODeviceBase
from PySide6.QtCore import QObject
from PySide6.QtCore import QJsonValue
from PySide6.QtCore import Property
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
    def got_result(sig, sige, future):
        try:
            sig.emit(future.result())
        except Exception as err:
            sige.emit(str(err))

    def outer_decorator(fn):
        @Slot(*args)
        @functools.wraps(fn)
        def wrapper(*args, **kwargs):
            sig = getattr(args[0], kws.get('sigSuccess'))

            opt = kws.get('sigError')
            sige = getattr(args[0], opt) if opt else None

            f = threadpool.submit(fn, *args)
            f.add_done_callback(functools.partial(got_result, sig, sige))

        return wrapper
    return outer_decorator


class GeminiInterface(QObject):
    srvResponse = Signal(dict, arguments=['resp'])
    srvError = Signal(str, arguments=['message'])

    fileDownloaded = Signal(dict, arguments=['resp'])
    fileDownloadError = Signal(str, arguments=['error'])

    dlqSizeChanged = Signal(int, arguments=['qsize'])

    def __init__(self, parent=None):
        super().__init__(parent)

        self.app = QApplication.instance()
        self._dcache = TTLCache(16, 60)
        self._dlq = deque([])

        self.certp = self.app.default_certp
        self.keyp = self.app.default_keyp

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

    @tSlot(str, QJsonValue, sigSuccess="fileDownloaded")
    def downloadToFile(self,
                       href: str,
                       options: QJsonValue):
        try:
            requ = URL(href)
            assert requ.scheme == 'gemini'

            self._dlq.appendleft(str(requ))
            self.dlqSizeChanged.emit(len(self._dlq))

            response = ignition.request(
                str(requ),
                ca_cert=(self.certp, self.keyp)
            )

            data = response.raw_body

            if response.is_a(ignition.SuccessResponse):
                with tempfile.NamedTemporaryFile(mode='wb',
                                                 delete=False) as file:
                    file.write(
                        data if isinstance(data, bytes) else data.encode())
            else:
                raise Exception(f'Download error for: {href}')

            self._dlq.remove(str(requ))
            self.dlqSizeChanged.emit(len(self._dlq))

            return {
                'url': href,
                'meta': response.meta,
                'path': file.name
            }
        except Exception:
            traceback.print_exc()
            raise

    @Slot(str, str, result=str)
    def buildUrl(self,
                 path: str,
                 baseUrl: str):
        return ignition.url(path, baseUrl)

    @tSlot(str, str, QJsonValue, sigSuccess="srvResponse")
    def geminiModelize(self,
                       href: str,
                       referer: str,
                       options: QJsonValue):
        linkno = 0
        model = []
        doc = GmiDocument()
        opts = options.toVariant()
        dlRootPath = opts.get('downloadsPath')

        try:
            requ = URL(href)

            response = ignition.request(
                str(requ),
                ca_cert=(self.certp, self.keyp),
                timeout=10
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

            if ctype != 'text/gemini':
                dstPath = Path(dlRootPath).joinpath(
                    requ.host).joinpath(requ.path.lstrip('/'))
                dstPath.parent.mkdir(parents=True, exist_ok=True)

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
            pf = []
            quoteb = []

            for line in doc.emit_line_objects(auto_tidy=True):
                if line.type != GmiLineType.QUOTE and quoteb:
                    # Flush the quote buffer and reset it
                    model.append({
                        'type': 'quote',
                        'text': '\n'.join(quoteb)
                    })
                    quoteb = []

                if line.type == GmiLineType.LINK:
                    # Compute keyboard sequence shortcut

                    url = URL(line.extra)
                    if url.scheme in ['http', 'https'] and \
                            self.app.levior_proc:
                        # Proxy web links to levior if it's running
                        upath = url.path if url.path else '/'
                        url = URL.build(
                            scheme='gemini',
                            host='localhost',
                            path=f'/{url.host}{upath}'
                        )
                    elif url.scheme in ['ipfs', 'ipns'] and \
                            self.app.levior_proc:
                        # IPFS urls, rewrite to go through the proxy
                        # Use dweb.link as the default gateway for now

                        host = f'{url.host}.{url.scheme}.dweb.link'
                        upath = url.path if url.path else '/'
                        url = URL.build(
                            scheme='gemini',
                            host='localhost',
                            path=f'/{host}/{upath}'
                        )

                    model.append({
                        'type': 'link',
                        'href': str(url),
                        'hrefPrev': hrefPrev,
                        'title': line.text if line.text else line.extra
                    })
                    hrefPrev = str(url)
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

            resp = {
                'url': href,
                'rsptype': rsptype,
                'model': model,
                'title': None
            }

            return resp
        except Exception:
            traceback.print_exc()

            self.srvError.emit(traceback.format_exc())


class GemalayaInterface(QObject):
    def __init__(self,
                 cfg_dir_path: Path,
                 cfg_path: Path,
                 config,
                 parent=None):
        super().__init__(parent)

        self.app = QApplication.instance()
        self.config = config
        self.cfg_dir_path = cfg_dir_path
        self.cfg_path = cfg_path

        self.localt_path = self.cfg_dir_path.joinpath('themes')
        self.mimes = self.loadExtraMimes()

    def loadExtraMimes(self):
        mp = Path(pkg_resources.resource_filename(
            'gemalaya', 'extra_mimes.json')
        )

        try:
            assert mp.is_file()

            with open(mp, 'r') as f:
                return json.loads(f.read())
        except Exception:
            return {}

    def __save_config(self):
        OmegaConf.save(config=self.config, f=str(self.cfg_path))

    @Slot(str, result=str)
    def mimeTypeGuess(self, filename: str):
        """
        Guess the MIME type of a file from its filename
        """

        mtype = None

        if filename.find('.') != -1:
            mtype = self.mimes.get(filename.rsplit('.', 1)[-1])

            if mtype is None:
                mtype, _ = mimetypes.guess_type(filename, strict=False)

        return mtype or 'application/octet-stream'

    @Slot(result=dict)
    def getConfig(self):
        return OmegaConf.to_container(self.config)

    @Slot(result=list)
    def themesNames(self):
        themes = []
        for theme in QDir(':/gemalaya/themes').entryList():
            themes.append(theme)

        for ent in self.localt_path.glob('*'):
            if ent.is_dir():
                themes.append(ent.name)

        return themes

    @Slot(str, result=dict)
    def getThemeConfig(self, themeName: str):
        """
        Return the config for a theme (custom theme from a file or qrc builtin)

        :rtype: dict
        """

        theme_default_path = Path(os.path.dirname(__file__)).joinpath(
            'theme_default.yaml'
        )

        # custom theme (local file)
        ctp = QFile(f'{self.cfg_dir_path}/themes/{themeName}/{themeName}.yaml')
        if ctp.exists():
            tfile = ctp
        else:
            tfile = QFile(f':/gemalaya/themes/{themeName}/{themeName}.yaml')
        try:
            tfile.open(QIODeviceBase.ReadOnly)
            data = tfile.readAll().data().decode()
            theme = OmegaConf.create(data)

            inherits = theme.get('inherits')
            if inherits:
                parent = self.getThemeConfig(inherits)
                if not parent:
                    raise ValueError(f'Invalid theme heritage: {inherits}')

                tcfg = OmegaConf.merge(
                    OmegaConf.create(parent),
                    theme
                )
            else:
                # merge with the defaults
                with open(theme_default_path, 'rt') as fd:
                    tcfg = OmegaConf.merge(
                        OmegaConf.load(fd),
                        theme
                    )

            if 0:
                print(json.dumps(OmegaConf.to_container(tcfg), indent=4))

            return OmegaConf.to_container(tcfg)
        except Exception:
            print(f'Error loading theme {themeName}: {traceback.format_exc()}')

    @Slot(str, str, result=str)
    def getThemeRscPath(self, themeName: str, path: str):
        """
        Returns the URL for a theme's resource

        :rtype: str
        """
        trp = QFile(f'{self.cfg_dir_path}/themes/{themeName}/{path}')
        if trp.exists():
            return trp.fileName()

        trp = QFile(f'qrc:/gemalaya/themes/{themeName}/{path}')
        if trp.exists():
            return f'qrc:/gemalaya/themes/{themeName}/{path}'

        # Use sinister as a backup for now
        return f'qrc:/gemalaya/themes/sinister/{path}'

    @Slot(str, result="QVariant")
    def get(self, attr: str):
        cur = self.config
        try:
            sections = attr.split('.')
            for s in sections[0:-1]:
                cur = cur.get(s)
                assert cur is not None

            return getattr(cur, sections[-1])
        except AttributeError:
            traceback.print_exc()
            return False
        except Exception:
            traceback.print_exc()
            return False

    @Slot(str, QJsonValue, result=bool)
    def set(self, attr: str, value: QJsonValue):
        """
        Set the value for a config setting
        """
        cur = self.config
        try:
            sections = attr.split('.')
            for s in sections[0:-1]:
                cur = cur.get(s)
                assert cur is not None

            setattr(cur, sections[-1], value.toVariant())
        except AttributeError:
            traceback.print_exc()
            return False
        except Exception:
            traceback.print_exc()
            return False
        else:
            self.__save_config()
            return True

    @Slot(str)
    def browserOpenUrl(self, urlString: str):
        """
        Open an external url with the webbrowser API
        """
        try:
            url = URL(urlString)
            assert url.scheme in ['http', 'https']

            webbrowser.open(str(url), new=2)
        except Exception:
            traceback.print_exc()

    @Slot(result=bool)
    def httpGatewayActive(self):
        return self.app.levior_proc is not None

    @Slot(str)
    def fileExec(self, filepath: str):
        try:
            assert 'downloadsPath' in self.config
            fp = Path(filepath)
            parents = [str(p) for p in fp.parents]

            assert self.config.downloadsPath in parents

            if platform.system() == 'Linux':
                subprocess.Popen(['xdg-open', filepath])
        except AssertionError:
            traceback.print_exc()
        except Exception:
            traceback.print_exc()

    @Slot()
    def quit(self):
        if self.app.levior_proc:
            print(f'Stopping levior (PID: {self.app.levior_proc.pid})')

            self.app.levior_proc.terminate()
            self.app.levior_proc.send_signal(signal.SIGTERM)
            self.app.levior_proc.kill()

        self.app.quit()
