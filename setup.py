import subprocess
from setuptools import setup
from setuptools import find_packages
from setuptools import Command
from distutils.command.build import build


def run(*args):
    p = subprocess.Popen(*args, stdout=subprocess.PIPE)
    stdout, err = p.communicate()
    return stdout


class build_gemalaya(Command):
    user_options = []

    def initialize_options(self):
        pass

    def finalize_options(self):
        pass

    def run(self):
        run([
            'pyside6-rcc',
            'gemalaya.qrc',
            '-o',
            'gemgemgem/ui_qml/rc_gemalaya.py'
        ])


class _build(build):
    sub_commands = [('build_gemalaya', None)] + build.sub_commands


setup(
    name='gemgemgem',
    version='0.3.1',
    description='A library to work with gemini and gempub archives',
    url='https://gitlab.com/galacteek/gemgemgem',
    author='cipres',
    keywords=['gemini', 'gempub'],
    packages=find_packages(),
    cmdclass={
        'build': _build,
        'build_gemalaya': build_gemalaya
    },
    install_requires=[
        'attrs',
        'DoubleLinkedList',
        'ebooklib',
        'ignition-gemini',
        'ipfshttpclient',
        'md2gemini @ git+https://github.com/pinnaculum/md2gemini#egg=md2gemini',
        'markdownify',
        'omegaconf>=2.3.0',
        'python-dateutil',
        'trimgmi',
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
            'PySide6-essentials>=6.5.1',
            'cryptography',
        ]
    },
    package_data={
        '': [
            '*.kv',
            '*.yaml'
        ],
        'gemgemgem.ui_qml': [
            '*.ttf'
        ],
        'gemgemgem.ui_qml.qml': [
            '*.qml',
            '*.png'
        ]
    },
    license='MIT',
    entry_points={
        'gui_scripts': [
            'gemv = gemgemgem.ui:run_gempubv',
            'gemalaya = gemgemgem.ui_qml:run_gemalaya',
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
