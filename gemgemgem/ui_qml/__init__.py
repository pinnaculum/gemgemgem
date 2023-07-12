import os.path
import argparse
import shutil
from pathlib import Path

from omegaconf import OmegaConf

from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtWidgets import QApplication
from PySide6.QtCore import QStandardPaths
from PySide6.QtGui import QFontDatabase

from gemgemgem.ui_qml import gemqti
from gemgemgem.ui_qml import rc_gemalaya  # noqa
from gemgemgem.x509 import x509SelfSignedGenerate

here = Path(os.path.dirname(__file__))
default_cfg_path = here.joinpath('default_config.yaml')


def run_gemalaya():
    parser = argparse.ArgumentParser()
    parser.add_argument('ebook', nargs='?')

    cfg_dir_path = Path(QStandardPaths.writableLocation(
        QStandardPaths.StandardLocation.ConfigLocation)).joinpath('gemalaya')
    cfg_dir_path.mkdir(parents=True, exist_ok=True)
    cfg_path = cfg_dir_path.joinpath('config.yaml')

    with open(default_cfg_path, 'rt') as cfd:
        default_config = OmegaConf.load(cfd)

    if not cfg_path.is_file():
        shutil.copy(str(default_cfg_path),
                    str(cfg_path))

    with open(cfg_path, 'rt') as cfd:
        config = OmegaConf.merge(
            default_config,
            OmegaConf.load(cfd)

        )

    certp = cfg_dir_path.joinpath('client.crt')
    keyp = cfg_dir_path.joinpath('client.key')

    if not certp.is_file() or not keyp.is_file():
        x509SelfSignedGenerate('gemalaya.org',
                               keyDestPath=keyp,
                               certDestPath=certp)

    qmlp = here.joinpath('qml')
    app = QApplication([])

    # NotoColorEmoji
    QFontDatabase.addApplicationFont(
        str(here.joinpath("NotoColorEmoji.ttf"))
    )

    engine = QQmlApplicationEngine()
    engine.addImportPath(str(qmlp))

    ctx = engine.rootContext()
    ctx.setContextProperty(
        'gem',
        gemqti.GeminiInterface((certp, keyp), app)
    )
    ctx.setContextProperty(
        'gemalaya',
        gemqti.GemalayaInterface(cfg_path, config, app)
    )

    engine.load(str(qmlp.joinpath("main.qml")))
    app.exec()
