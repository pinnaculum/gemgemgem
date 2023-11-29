import os
import subprocess

from setuptools import setup
from setuptools import find_packages
from setuptools import Command

from distutils.command.build import build
from distutils.version import StrictVersion

from datetime import date


with open('VERSION', 'rt') as vf:
    __version__ = vf.read().split('\n')[0]


def run_rcc(*args):
    p = subprocess.Popen(*args, stdout=subprocess.PIPE)
    stdout, err = p.communicate()

    [print(f'RCC => {line}') for line in stdout.decode().split('\n') if line]


class vbump(Command):
    user_options = [
        ("version=", None, 'Version'),
        ("cl=", None, 'Add changelog entry')
    ]

    def initialize_options(self):
        self.version = None
        self.cl = None

    def finalize_options(self):
        pass

    def run(self):
        today = date.today()

        if not self.version:
            raise ValueError('No version specified')

        v = StrictVersion(self.version)
        assert v.version[0] is not None
        assert v.version[1] is not None
        assert v.version[2] is not None

        with open('VERSION', 'wt') as f:
            f.write(f"{self.version}\n")

        os.system('git add VERSION')

        if self.cl:
            with open('CHANGELOG.md', 'rt') as f:
                cl = f.read()

            with open('CHANGELOG.md', 'wt') as cf:
                cf.write(
                    f'## [{self.version}] - {today}\n')
                cf.write('\n### Added\n')
                cf.write('\n### Changed\n\n')
                cf.write(cl)

            os.system('git add CHANGELOG.md')


class build_gemalaya(Command):
    user_options = []

    def initialize_options(self):
        pass

    def finalize_options(self):
        pass

    def run(self):
        run_rcc([
            'pyside6-rcc',
            'gemalaya.qrc',
            '-o',
            'gemalaya/rc_gemalaya.py'
        ])


class _build(build):
    sub_commands = [('build_gemalaya', None)] + build.sub_commands


setup(
    name='gemgemgem',
    version=__version__,
    description='Collection of Gemini apps and tools',
    url='https://gitlab.com/cipres/gemgemgem',
    author='cipres',
    keywords=['gemini', 'gempub'],
    packages=find_packages(),
    cmdclass={
        'build_gemalaya': build_gemalaya,
        'vbump': vbump
    },
    install_requires=[
        'attrs',
        'cachetools',
        'deep-translator==1.11.4',
        'DoubleLinkedList',
        'ebooklib==0.18',
        'feedparser==6.0.10',
        'ignition-gemini @ '
        'git+https://gitlab.com/cipres/ignition#'
        '1b01b54031d8dcb1bfd46bdab13f52c7cf3d5ef6',
        'misfin @ '
        'git+https://gitlab.com/cipres/misfin#'
        'c19fb5d245825ba8d7769cb1189777d4a54193f0',
        'ipfshttpclient==0.7.0',
        'md2gemini @ '
        'git+https://github.com/pinnaculum/md2gemini#egg=md2gemini',
        'markdownify==0.11.6',
        'omegaconf==2.3.0',
        'python-dateutil==2.8.2',
        'rst2gemtext==0.3.1',
        'trimgmi==0.3.0',
        'yarl'
    ],
    extras_require={
        'ui': [
            'kivy'
        ],
        'gemv': [
            'kivy'
        ],
        'gemalaya': [
            'gTTS==2.3.2',
            'langdetect==1.0.9',
            'PySide6-essentials==6.5.2',
            'cffi',
            'cryptography',
        ],
        'gemalaya-http-proxy': [
            'levior @ git+https://gitlab.com/cipres/levior#'
            '2db771bde0f18af502f1d023693ddb84ce4a45ad'
        ]
    },
    package_data={
        '': [
            '*.kv',
            '*.yaml'
        ],
        'gemalaya': [
            '*.ttf',
            '*.json'
        ],
        'gemalaya.qml': [
            'qmldir',
            '*.qml',
            '*.png'
        ]
    },
    include_package_data=True,
    license='MIT',
    entry_points={
        'gui_scripts': [
            'gemv = gemgemgem.ui:run_gempubv',
            'gemalaya = gemalaya:run_gemalaya',
        ],
        'console_scripts': [
            'gempubify = gemgemgem.gempubify:gempubify'
        ]
    },
    classifiers=[
        'Development Status :: 2 - Pre-Alpha',
        'Environment :: X11 Applications',
        'Environment :: Console',
        'Intended Audience :: Developers',
        'Intended Audience :: End Users/Desktop',
        'License :: OSI Approved :: MIT License',
        'Operating System :: OS Independent',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9'
    ]
)
