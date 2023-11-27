import sys
import os
import os.path
import argparse
import shutil
import concurrent.futures
import subprocess
from pathlib import Path

import ignition
from omegaconf import OmegaConf

from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQml import qmlRegisterType
from PySide6.QtWidgets import QApplication
from PySide6.QtCore import QStandardPaths
from PySide6.QtCore import Qt
from PySide6.QtCore import QThreadPool
from PySide6.QtGui import QFontDatabase

from gemalaya import gemqti
from gemalaya import sqldb
from gemalaya import updates
from gemalaya import rc_gemalaya  # noqa
from gemalaya.identities import IdentitiesManager
from gemgemgem.x509 import x509SelfSignedGenerate


app_name = 'gemalaya'
here = Path(os.path.dirname(__file__))
qmlp = here.joinpath('qml')
default_cfg_path = here.joinpath('default_config.yaml')
def_bm_path = here.joinpath('bookmarks.yaml')
pyv = f'{sys.version_info.major}.{sys.version_info.minor}'


def run_levior(cfg_dir_path: Path,
               data_path: Path) -> subprocess.Popen:
    levior_dir = cfg_dir_path.joinpath('levior')
    levior_dir.mkdir(parents=True, exist_ok=True)

    levior_cache_dir = data_path.joinpath('levior').joinpath('cache')
    levior_cache_dir.mkdir(parents=True, exist_ok=True)

    lev_path = shutil.which('levior')

    if lev_path:
        return subprocess.Popen([
            f'python{pyv}',
            lev_path,
            '--cache-path',
            str(levior_cache_dir),
            '--cache-enable',
            '--mode=proxy'
        ])


def venvsitepackages(venvp: Path):
    return str(venvp.joinpath('lib').joinpath(
        f'python{pyv}').joinpath('site-packages'))


def run_gemalaya():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--run-proxy',
        '--run-http-proxy',
        '--run-levior',
        action='store_true',
        dest='levior',
        default=False,
        help='Run the http-to-gemini proxy service (levior)'
    )
    parser.add_argument(
        '--no-proxy',
        '--no-levior',
        action='store_true',
        dest='nolevior',
        default=False,
        help='Do not run the http-to-gemini proxy service (levior)'
    )
    parser.add_argument(
        '--git-branch',
        dest='git_branch',
        default='master'
    )

    args = parser.parse_args()

    # Config paths
    cfg_dir_path = Path(QStandardPaths.writableLocation(
        QStandardPaths.StandardLocation.ConfigLocation)).joinpath(app_name)
    cfg_dir_path.mkdir(parents=True, exist_ok=True)
    cfg_dir_path.joinpath('themes').mkdir(parents=True, exist_ok=True)
    cfg_path = cfg_dir_path.joinpath('config.yaml')

    # identities path
    identities_path = cfg_dir_path.joinpath('identities')
    identities_path.mkdir(parents=True, exist_ok=True)

    # Data path
    data_path = Path(QStandardPaths.writableLocation(
        QStandardPaths.StandardLocation.AppDataLocation
    )).joinpath(app_name)
    data_path.mkdir(parents=True, exist_ok=True)
    sqldb_path = data_path.joinpath('gemalaya.sqlite')

    # Dl path
    downloads_path = Path(QStandardPaths.writableLocation(
        QStandardPaths.StandardLocation.DownloadLocation
    )).joinpath(app_name)
    downloads_path.mkdir(parents=True, exist_ok=True)

    # Load the default config
    with open(default_cfg_path, 'rt') as cfd:
        default_config = OmegaConf.load(cfd)

    # Copy default config if there's no config yet
    if not cfg_path.is_file():
        shutil.copy(str(default_cfg_path),
                    str(cfg_path))

    # Merge with default config and save
    with open(cfg_path, 'rt') as cfd:
        config = OmegaConf.merge(
            default_config,
            OmegaConf.load(cfd)
        )

    if 'downloadsPath' not in config:
        config.downloadsPath = str(downloads_path)

    OmegaConf.save(config, f=str(cfg_path))

    # Set ignition's known hosts file path
    ignition.set_default_hosts_file(
        str(data_path.joinpath('ignition_known_hosts'))
    )

    # certs
    certp = cfg_dir_path.joinpath('client.crt')
    keyp = cfg_dir_path.joinpath('client.key')

    if not certp.is_file() or not keyp.is_file():
        x509SelfSignedGenerate('gemalaya.org',
                               keyDestPath=keyp,
                               certDestPath=certp)

    app = QApplication([])
    app.threadpool = concurrent.futures.ThreadPoolExecutor()
    app.levior_proc = None
    app.identities = IdentitiesManager(identities_path)

    app.misfin_identities_path = cfg_dir_path.joinpath('misfin_identities')
    app.misfin_identities_path.mkdir(parents=True, exist_ok=True)
    app.default_misfin_identity = app.misfin_identities_path.joinpath(
        'default.pem'
    )

    # Run levior if requested
    if (config.levior.enable is True or args.levior is True) and \
       args.nolevior is False:
        app.levior_proc = run_levior(cfg_dir_path, data_path)

    # NotoColorEmoji
    QFontDatabase.addApplicationFont(
        str(here.joinpath("NotoColorEmoji.ttf"))
    )

    sqldb.create_db(str(sqldb_path))

    with open(def_bm_path, 'rt') as fd:
        bml = OmegaConf.load(fd)

        for bm in bml:
            sqldb.add_bookmark(bm.url, bm.get('title', ''))

    bmodel = sqldb.BookmarksTableModel()
    bmodel.setTable('bookmarks')
    bmodel.setHeaderData(0, Qt.Horizontal, 'URL')
    bmodel.setHeaderData(1, Qt.Horizontal, 'Title')
    bmodel.select()

    qmlRegisterType(
        gemqti.GeminiInterface,
        'Gemalaya',
        1, 0,
        'GeminiAgent'
    )
    qmlRegisterType(
        gemqti.TTSInterface,
        'Gemalaya',
        1, 0,
        'TextToSpeech'
    )
    qmlRegisterType(
        gemqti.TextTranslateInterface,
        'Gemalaya',
        1, 0,
        'TextTranslator'
    )

    qmlRegisterType(
        gemqti.MisfinInterface,
        'Gemalaya',
        1, 0,
        'Misfin'
    )

    engine = QQmlApplicationEngine()
    engine.addImportPath(str(qmlp))

    app.default_certp = certp
    app.default_keyp = keyp
    app.qtp = QThreadPool()
    app.gtts_cache_path = data_path.joinpath('gtts_cache')
    app.gtts_cache_path.mkdir(parents=True, exist_ok=True)
    app.picotts_cache_path = data_path.joinpath('picotts_cache')
    app.picotts_cache_path.mkdir(parents=True, exist_ok=True)

    app.main_iface = gemqti.GemalayaInterface(
        cfg_dir_path,
        cfg_path,
        config, app)

    app.wheelWorker = updates.WheelInstallWorker(app.main_iface)

    # QML engine setup
    ctx = engine.rootContext()
    ctx.setContextProperty(
        'gem',
        gemqti.GeminiInterface(app)
    )
    ctx.setContextProperty(
        app_name,
        app.main_iface
    )

    ctx.setContextProperty(
        'bookmarksModel',
        bmodel
    )

    c_updates_mode = config.updates.get('check_updates_mode', 'never')

    # Wheel update worker
    if os.getenv('APPIMAGE') and c_updates_mode == 'automatic':
        app.qtp.start(updates.CheckUpdatesWorker(app.main_iface,
                                                 args.git_branch))

    # Load main.qml and run the app
    engine.load(str(qmlp.joinpath("main.qml")))
    app.exec()
