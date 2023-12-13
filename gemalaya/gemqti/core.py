import json
import mimetypes
import os
import os.path
import pkg_resources
import platform
import re
import sys
import traceback
import signal
import shutil
import subprocess
import webbrowser

from datetime import datetime
from pathlib import Path
from yarl import URL
from omegaconf import OmegaConf
from omegaconf import errors as omega_errors

from gtts.lang import tts_langs

import langdetect

from PySide6.QtCore import QDir
from PySide6.QtCore import QFile
from PySide6.QtCore import QIODeviceBase
from PySide6.QtCore import QObject
from PySide6.QtCore import QJsonValue
from PySide6.QtCore import Slot
from PySide6.QtCore import Signal
from PySide6.QtGui import QClipboard
from PySide6.QtWidgets import QApplication

from .qt import tSlot


class GemalayaInterface(QObject):
    updateAvailable = Signal(str, str, arguments=['version', 'wheelUrl'])
    updateInstalled = Signal()
    updateError = Signal(str, arguments=['errmessage'])

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
        self.isnippets_path = self.cfg_dir_path.joinpath('isnippets')
        self.mimes = self.loadExtraMimes()

        # URL of the remote wheel for updates
        self.wheelUpdateUrl: URL = None

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
    def getClipboardUrl(self, mode: str):
        """
        If there's a valid URL stored in the clipboard, return it as a string
        """

        if not mode or mode == 'auto':
            cms = [QClipboard.Clipboard,
                   QClipboard.Selection]
        elif mode == 'clipboard':
            cms = [QClipboard.Clipboard]
        elif mode == 'system':
            cms = [QClipboard.Selection]
        else:
            cms = [QClipboard.Clipboard]

        for cm in cms:
            try:
                url = URL(self.app.clipboard().text(cm))
                assert url.scheme

                return str(url)
            except Exception:
                continue

    @Slot(str)
    def setClipboardText(self, text: str):
        # Copy to both clipboards for now

        self.app.clipboard().setText(text, QClipboard.Clipboard)
        self.app.clipboard().setText(text, QClipboard.Selection)

    @Slot(str, result=bool)
    def installWheelUpdate(self, wheelUrl: str):
        self.app.wheelWorker.wheelUrl = wheelUrl
        self.app.qtp.start(self.app.wheelWorker)
        return True

    @Slot()
    def checkUpdates(self):
        from . import updates

        self.app.qtp.start(updates.CheckUpdatesWorker(self))

    @Slot(result=list)
    def inputSnippets(self):
        """
        Return snippets that can be used to reply for input responses
        """

        snipl = []
        if not self.isnippets_path.is_dir():
            return snipl

        for file in self.isnippets_path.glob('*'):
            try:
                with open(file, 'rt') as f:
                    basename, fext = os.path.splitext(file.name)
                    snipl.append({
                        'name': basename,
                        'text': f.read()
                    })
            except Exception:
                continue

        return snipl

    @Slot(str, str, bool, result=bool)
    def inputSnippetSave(self, name: str, content: str, overwrite: bool):
        """
        Store a snippet for gemini input responses
        """
        self.isnippets_path.mkdir(exist_ok=True, parents=True)

        dstf = self.isnippets_path.joinpath(name)
        try:
            with open(dstf, 'wt') as f:
                f.write(content)
        except Exception:
            return False

        return True

    @Slot(str, result=str)
    def langDetect(self, text: str):
        """
        Detect the language that this text is written in
        """
        try:
            return langdetect.detect(text)
        except Exception:
            # Default
            return 'en'

    @Slot(result=list)
    def tsTargetLangCodes(self):
        pslangs = list(sorted(self.config.ui.translate.targetLangs.items(),
                              key=lambda it: it[1]['prio']))

        return [
            code for code, cfg in pslangs if cfg.get('enabled', True) is True
        ]

    @Slot(result=list)
    def gttsLangsList(self):
        return list(tts_langs().keys())

    @Slot(str, str, result=str)
    def mimeTypeGuess(self, filename: str,
                      default: str):
        """
        Guess the MIME type of a file from its filename
        """

        mtype = None

        if filename.find('.') != -1:
            mtype = self.mimes.get(filename.rsplit('.', 1)[-1])

            if mtype is None:
                mtype, _ = mimetypes.guess_type(filename, strict=False)

        return mtype or default

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

        theme_default_path = Path(pkg_resources.resource_filename(
            'gemalaya', 'theme_default.yaml')
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

            val = getattr(cur, sections[-1])
            if type(val) in [int, float, str, bool]:
                return val
            else:
                return OmegaConf.to_container(val)
        except omega_errors.ConfigAttributeError:
            return None
        except AttributeError:
            traceback.print_exc()
            return None
        except Exception:
            traceback.print_exc()
            return None

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

    @Slot(str, result=str)
    def urlExpand(self, input: str):
        for n, rule in self.config.get('urlCommander', {}).items():
            try:
                m = rf"{rule.match}"
                rewrite = rf"{rule.to}"

                if rule.get('enabled') is False or rule.get('obsolete'):
                    continue

                if not isinstance(m, str) or not isinstance(rewrite, str):
                    continue

                if re.match(m, input):
                    result = re.sub(m, rewrite, input)
                    if result:
                        return result
            except Exception:
                traceback.print_exc()
                continue

        return ''

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

        # Cleanup old files in the gtts cache
        now = datetime.now()
        maxDays = self.config.ui.tts.get('mp3CacheForDays', 1)

        for file in list(self.app.gtts_cache_path.glob('*.mp3')) + \
                list(self.app.picotts_cache_path.glob('*.wav')):
            try:
                diff = now - datetime.fromtimestamp(file.stat().st_ctime)

                if diff.days > maxDays:
                    file.unlink()
            except Exception:
                traceback.print_exc()
                continue

        self.app.quit()


class MisfinInterface(QObject):
    sent = Signal(str, arguments=['destination'])
    sendError = Signal(str, arguments=['errorMessage'])

    def __init__(self, parent=None):
        super().__init__(parent)

        self.app = QApplication.instance()

    def _misfin_run(self, args):
        if os.getenv('APPIMAGE'):
            pyv = f'{sys.version_info.major}.{sys.version_info.minor}'
            cmd = [f'python{pyv}', shutil.which('misfin')] + args
        else:
            cmd = ['misfin'] + args

        p = subprocess.Popen(cmd, stdout=subprocess.PIPE)
        p.wait()
        return p

    @Slot(result=str)
    def defaultIdentityPath(self):
        return str(self.app.default_misfin_identity)

    @Slot(result=bool)
    def defaultIdentityExists(self):
        return self.app.default_misfin_identity.is_file()

    @Slot(result=list)
    def identitiesNames(self):
        return list(self.app.misfin_identities_path.glob('*.pem'))

    @Slot(str, result=str)
    def identityPath(self, name: str):
        return str(self.app.misfin_identities_path.joinpath(f'{name}.pem'))

    @Slot(str, str, str, str, result=bool)
    def makeCert(self,
                 mailbox: str, blurb: str, hostname: str,
                 output: str):
        p = self._misfin_run([
            'make-cert',
            mailbox,
            blurb,
            hostname,
            output
        ])
        return p.returncode == 0

    @tSlot(str, str, str, sigSuccess="sent", sigError="sendError")
    def send(self,
             senderPem: str,
             destination: str,
             message: str):
        p = self._misfin_run([
            'send-as',
            senderPem,
            destination,
            message
        ])
        if p.returncode == 0:
            return destination
        else:
            raise Exception(f'Misfin send error (return code {p.returncode}')
