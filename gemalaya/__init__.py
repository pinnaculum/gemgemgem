import os.path
import argparse
import shutil
import concurrent.futures
from pathlib import Path

from omegaconf import OmegaConf

from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQml import qmlRegisterType
from PySide6.QtWidgets import QApplication
from PySide6.QtCore import QStandardPaths
from PySide6.QtCore import Qt
from PySide6.QtCore import QDir
from PySide6.QtCore import QFile
from PySide6.QtCore import QIODeviceBase
from PySide6.QtGui import QFontDatabase

from gemalaya import gemqti
from gemalaya import sqldb
from gemalaya import rc_gemalaya  # noqa
from gemgemgem.x509 import x509SelfSignedGenerate

app_name = 'gemalaya'
here = Path(os.path.dirname(__file__))
qmlp = here.joinpath('qml')
default_cfg_path = here.joinpath('default_config.yaml')


def run_gemalaya():
    parser = argparse.ArgumentParser()
    parser.add_argument('ebook', nargs='?')

    # Config paths
    cfg_dir_path = Path(QStandardPaths.writableLocation(
        QStandardPaths.StandardLocation.ConfigLocation)).joinpath(app_name)
    cfg_dir_path.mkdir(parents=True, exist_ok=True)
    cfg_path = cfg_dir_path.joinpath('config.yaml')

    # Data path
    data_path = Path(QStandardPaths.writableLocation(
        QStandardPaths.StandardLocation.AppDataLocation
    )).joinpath(app_name)
    data_path.mkdir(parents=True, exist_ok=True)
    sqldb_path = data_path.joinpath('gemalaya.sqlite')

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

    # Load the themes

    for themeName in QDir(':/gemalaya/themes').entryList():
        tc = QFile(f':/gemalaya/themes/{themeName}/theme.yaml')
        try:
            tc.open(QIODeviceBase.ReadOnly)
            data = tc.readAll().data().decode()

            config = OmegaConf.merge(
                config,
                OmegaConf.create(data)
            )
        except Exception as err:
            print(f'Error loading theme {themeName}: {err}')

    OmegaConf.save(config, f=str(cfg_path))

    # certs
    certp = cfg_dir_path.joinpath('client.crt')
    keyp = cfg_dir_path.joinpath('client.key')

    if not certp.is_file() or not keyp.is_file():
        x509SelfSignedGenerate('gemalaya.org',
                               keyDestPath=keyp,
                               certDestPath=certp)

    app = QApplication([])
    app.threadpool = concurrent.futures.ThreadPoolExecutor()

    # NotoColorEmoji
    QFontDatabase.addApplicationFont(
        str(here.joinpath("NotoColorEmoji.ttf"))
    )

    sqldb.create_db(str(sqldb_path))

    bmodel = sqldb.BookmarksTableModel()
    bmodel.setTable('bookmarks')
    bmodel.setHeaderData(0, Qt.Horizontal, 'Title')
    bmodel.setHeaderData(1, Qt.Horizontal, 'URL')
    bmodel.select()

    qmlRegisterType(
        gemqti.GeminiInterface,
        'Gemalaya',
        1, 0,
        'GeminiAgent'
    )

    engine = QQmlApplicationEngine()
    engine.addImportPath(str(qmlp))

    app.default_certp = certp
    app.default_keyp = keyp

    # QML engine setup
    ctx = engine.rootContext()
    ctx.setContextProperty(
        'gem',
        gemqti.GeminiInterface(app)
    )
    ctx.setContextProperty(
        app_name,
        gemqti.GemalayaInterface(cfg_path, config, app)
    )

    ctx.setContextProperty(
        'bookmarksModel',
        bmodel
    )

    # Load main.qml and run the app
    engine.load(str(qmlp.joinpath("main.qml")))
    app.exec()
