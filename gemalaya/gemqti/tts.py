import hashlib
import os
import os.path
import re
import tempfile
import traceback
import shutil
import subprocess

from pathlib import Path

from gtts import gTTS
from gtts.tts import gTTSError
from gtts.tokenizer import pre_processors

import langdetect

from PySide6.QtCore import QObject
from PySide6.QtCore import Signal
from PySide6.QtWidgets import QApplication

from .qt import tSlot

import functools


class TTSInterface(QObject):
    converted = Signal(str, arguments=['filepath'])
    convertError = Signal(str, arguments=['error'])

    def __init__(self, parent=None):
        super().__init__(parent)

        self.app = QApplication.instance()
        self._tmp_audio_files = []
        self.destroyed.connect(functools.partial(self.onDestroyed))

    @property
    def config(self):
        return self.app.main_iface.config

    @property
    def engine(self):
        return self.config.ui.tts.get('engine', 'nanotts')

    def onDestroyed(self):
        for tmpf in self._tmp_audio_files:
            try:
                os.unlink(tmpf)
            except Exception:
                continue

    def _preproc_clean(self, text: str) -> str:
        # Keep alphanumerical characters, stuff inside
        # parentheses, and most ponctuation marks
        # Remove anything inside square brackets

        return ' '.join(re.findall(
            r"[\(^\)]+|\w+|[?!,\.;:]+",
            re.sub(
                r'\[.*?\]|[\-\+]',
                '',
                text
            )
        ))

    @tSlot(str, dict, sigSuccess="converted", sigError="convertError")
    def save(self, rtext: str, options: dict):
        """
        Convert some text to an audio file with the TTS engine
        set in the config.
        """

        langtag = options.get('lang',
                              langdetect.detect(rtext))
        hexdigest = hashlib.sha256(rtext.encode()).hexdigest()

        if self.engine == 'gtts':
            return self._save_gtts(rtext, hexdigest, langtag, options)
        elif self.engine == 'picotts':
            return self._save_picotts(rtext, hexdigest, langtag, options)
        elif self.engine == 'nanotts':
            return self._save_nanotts(rtext, hexdigest, langtag, options)
        else:
            raise ValueError(f'Unsupported TTS engine: {self.engine}')

    def lang_to_picovoice(self, langtag: str) -> str:
        # lang tag to pico voice name dictionary mapping
        voices = {
            'de': 'de-DE',
            'en': 'en-GB',
            'es': 'es-ES',
            'fr': 'fr-FR',
            'it': 'it-IT'
        }

        return voices.get(langtag)

    def _save_nanotts(self,
                      rtext: str,
                      digest: str,
                      langtag: str,
                      options: dict) -> str:
        """
        Convert some text to an audio (WAV) file with NanoTTS and
        return the path of the audio file.
        """

        if not shutil.which('nanotts'):
            raise Exception('nanotts was not found!')

        voice = self.lang_to_picovoice(langtag)

        if not voice:
            raise ValueError(f'Voice not found for language: {langtag}')

        nano_opts = self.config.ui.tts.nanotts_options

        # LINGWARE_VOICES_PATH is set in the AppRun
        lw_voices_path = os.environ.get('LINGWARE_VOICES_PATH',
                                        '/usr/share/pico/lang')

        pitch = nano_opts.get('pitch', 100) / 100
        speed = nano_opts.get('speed', 100) / 100
        volume = nano_opts.get('volume', 100) / 100

        if options.get('test', False) is True:
            dstf = Path(tempfile.mkstemp(suffix='.wav')[1])
        else:
            dstf = self.app.picotts_cache_path.joinpath(
                f'{digest}_{voice}.wav')

            if dstf.is_file():
                return str(dstf)

        with tempfile.NamedTemporaryFile(mode='wt', suffix='.txt') as ifile:
            ifile.write(self._preproc_clean(rtext))
            ifile.flush()

            proc = subprocess.Popen([
                'nanotts',
                '--speed', str(speed),
                '--pitch', str(pitch),
                '--volume', str(volume),
                '-l', lw_voices_path,
                '-v', voice,
                '-o', str(dstf),
                '-f', ifile.name
            ], stdout=subprocess.PIPE)

            proc.wait()

        if proc.returncode == 0:
            return str(dstf)
        else:
            raise Exception(
                f'nanotts exited with retcode {proc.returncode}')

    def _save_picotts(self,
                      rtext: str,
                      digest: str,
                      langtag: str,
                      options: dict) -> str:
        """
        Convert some text to an audio (WAV) file with PicoTTS and
        return the path of the audio file.
        """

        if not shutil.which('pico2wave'):
            raise Exception('picotts: pico2wave was not found!')

        voice = self.lang_to_picovoice(langtag)

        if not voice:
            raise ValueError(f'Pico TTS voice not found for lang: {langtag}')

        if options.get('test', False) is True:
            dstf = Path(tempfile.mkstemp(suffix='.wav')[1])
        else:
            dstf = self.app.picotts_cache_path.joinpath(
                f'{digest}_{voice}.wav')

            if dstf.is_file():
                return str(dstf)

        proc = subprocess.Popen([
            'pico2wave',
            '-l',
            voice,
            '-w',
            str(dstf),
            rtext
        ], stdout=subprocess.PIPE)

        proc.wait()

        if proc.returncode == 0:
            return str(dstf)
        else:
            raise Exception(
                f'pico2wave exited with retcode {proc.returncode}')

    def _save_gtts(self,
                   rtext: str,
                   digest: str,
                   langtag: str,
                   options: dict) -> str:
        """
        Convert some text to an audio (mp3) file with gTTS, and
        return the path of the audio file.
        """
        preproc = [
            pre_processors.tone_marks,
            pre_processors.end_of_line,
            pre_processors.abbreviations,
            pre_processors.word_sub,
            self._preproc_clean
        ]

        try:
            tld = options.get('tld', 'com')

            if not langtag:
                raise ValueError('No language tag!')

            dstp = self.app.gtts_cache_path.joinpath(f'{digest}_{langtag}.mp3')

            if dstp.is_file():
                # We already did a TTS for this text
                # TODO: do a real check on the validity of the mp3 file
                return str(dstp)

            ttso = gTTS(text=rtext,
                        lang=langtag,
                        tld=tld,
                        pre_processor_funcs=preproc,
                        slow=options.get('slow', False))

            ttso.save(str(dstp))
            assert dstp.is_file()

            return str(dstp)
        except (gTTSError, AssertionError, ValueError):
            raise
        except Exception:
            traceback.print_exc()
            return None
