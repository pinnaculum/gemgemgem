from setuptools import setup
from setuptools import find_packages


setup(
    name='gemgemgem',
    version='0.3.1',
    description='A library to work with gemini and gempub archives',
    url='https://gitlab.com/galacteek/gemgemgem',
    author='cipres',
    keywords=['gemini', 'gempub'],
    packages=find_packages(),
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
            'PyQt6>=6.5.1',
            'cryptography',
        ]
    },
    package_data={
        '': [
            '*.kv'
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
