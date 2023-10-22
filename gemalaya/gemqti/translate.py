import re
import traceback

import langdetect

from PySide6.QtCore import QObject
from PySide6.QtCore import Signal
from PySide6.QtWidgets import QApplication

from .qt import tSlot

from deep_translator import constants
from deep_translator import MyMemoryTranslator
from deep_translator.exceptions import TooManyRequests


def myml_fromtag(langtag: str) -> str:
    # get mymemory language name from a lang tag ('en' => 'english')

    for lang, code in constants.MY_MEMORY_LANGUAGES_TO_CODES.items():
        if '-' in code:
            mcode, m2 = code.split('-', 1)
            if mcode == langtag:
                return lang
        elif code == langtag:
            return lang


class TextTranslateInterface(QObject):
    translated = Signal(str, str,
                        arguments=['translatedText', 'targetLangTag'])
    translateError = Signal(str, arguments=['error'])

    @property
    def config(self):
        return QApplication.instance().main_iface.config

    @tSlot(str, dict, sigSuccess="translated", sigError="translateError")
    def translate(self, itext: str, options: dict):
        src_lang = myml_fromtag(
            options.get('srclang', langdetect.detect(itext))
        )

        target_lang_tag = options.get('dstlang', 'en')
        target_lang = myml_fromtag(target_lang_tag)

        if not src_lang or not target_lang:
            raise ValueError('Cannot determine src/dst languages')

        try:
            if len(itext) > 499:
                sts = re.split(r'(?<=\.)[ \n]', itext)

                translated = ''.join([MyMemoryTranslator(
                    source=src_lang,
                    target=target_lang).translate(t) for t in sts])
            else:
                translated = MyMemoryTranslator(
                    source=src_lang,
                    target=target_lang).translate(itext)

            assert translated
        except TooManyRequests:
            raise Exception('Too many requests!')
        except Exception:
            traceback.print_exc()
            raise Exception(f'Could not translate text to {target_lang}')
        else:
            return (translated, target_lang_tag)
