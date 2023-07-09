import os.path
import argparse
from pathlib import Path

from PyQt6.QtQml import QQmlApplicationEngine
from PyQt6.QtWidgets import QApplication
from PyQt6.QtCore import QStandardPaths
from PyQt6.QtGui import QFontDatabase

from gemgemgem.ui_qml import gemqti
from gemgemgem.x509 import x509SelfSignedGenerate

here = Path(os.path.dirname(__file__))


def run_gemalaya():
    parser = argparse.ArgumentParser()
    parser.add_argument('ebook', nargs='?')

    cfgp = Path(QStandardPaths.writableLocation(
        QStandardPaths.StandardLocation.ConfigLocation)).joinpath('gemalaya')
    cfgp.mkdir(parents=True, exist_ok=True)

    certp = cfgp.joinpath('client.crt')
    keyp = cfgp.joinpath('client.key')

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

    engine.load(str(qmlp.joinpath("main.qml")))
    app.exec()
