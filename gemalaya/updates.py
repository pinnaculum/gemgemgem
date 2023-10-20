import tempfile
import re
import subprocess
import shutil
import sys
import time
import traceback
from pathlib import Path

from yarl import URL

from urllib.request import urlopen
from urllib.request import HTTPErrorProcessor
from urllib.request import build_opener

from distutils.version import StrictVersion
from importlib.metadata import version

from PySide6.QtCore import QRunnable
from PySide6.QtCore import Slot


from .gemqti import GemalayaInterface


def wheel_url(project: str = 'cipres/gemgemgem',
              branch: str = 'master',
              wheel_name: str = 'gemgemgem') -> URL:
    return URL.build(
        scheme='https',
        host='gitlab.com',
        path=f'/{project}/-/releases/continuous-{branch}/'
        f'downloads/{wheel_name}-latest-py3-none-any.whl'
    )


class NoRedirectionOpener(HTTPErrorProcessor):
    def http_response(self, request, response):
        return response

    https_response = http_response


def pip_install_wheel(url: URL):
    pyv = f'{sys.version_info.major}.{sys.version_info.minor}'

    with tempfile.TemporaryDirectory() as tmpd:
        dstfp = Path(tmpd).joinpath(url.name)

        with open(dstfp, 'wb') as file:
            with urlopen(str(url)) as resp:
                file.write(resp.read())

        p = subprocess.Popen(
            [shutil.which(f'python{pyv}'),
             '-m', 'pip',
             'install', '--user', '-U',
             f'{dstfp}[gemalaya]'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )

        out, err = p.communicate()

        if out:
            print(out.decode())
        if err:
            print(f'Pip error: {err.decode()}', file=sys.stderr)

        return p.returncode


def checkWheelUpdate(gem_iface: GemalayaInterface,
                     git_branch: str) -> tuple:
    opener = build_opener(NoRedirectionOpener)

    try:
        localv = StrictVersion(version('gemgemgem'))
        wurl = wheel_url(branch=git_branch)

        resp = opener.open(str(wurl))
        assert 'Location' in resp.headers
        location = URL(resp.headers['Location'])

        match = re.search(r'(\d+\.\d+\.\d+)', location.name)
        wheelv = StrictVersion(match.group(1))

        assert location

        if wheelv > localv:
            return wheelv, wurl

        return None, None
    except Exception:
        traceback.print_exc()
        return None, None


class CheckUpdatesWorker(QRunnable):
    def __init__(self, iface: GemalayaInterface,
                 git_branch: str = 'master'):
        super().__init__()

        self.iface = iface
        self.git_branch: str = git_branch

    @Slot()
    def run(self):
        time.sleep(3)

        newv, wurl = checkWheelUpdate(self.iface, self.git_branch)
        if newv:
            self.iface.wheelUpdateUrl = wurl
            self.iface.updateAvailable.emit(str(newv), str(wurl))


class WheelInstallWorker(QRunnable):
    def __init__(self, iface: GemalayaInterface):
        super().__init__()

        self.iface = iface
        self.wheelUrl: str = None

    @Slot()
    def run(self):
        if self.iface.wheelUpdateUrl:
            try:
                retcode = pip_install_wheel(self.iface.wheelUpdateUrl)
                if retcode == 0:
                    self.iface.updateInstalled.emit()
                else:
                    self.iface.updateError.emit('pip error')
            except Exception:
                traceback.print_exc()
