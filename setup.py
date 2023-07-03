from setuptools import setup


setup(
    name='gemgemgem',
    version='0.3.0',
    description='A library to work with gemini and gempub archives',
    url='https://gitlab.com/galacteek/gemgemgem',
    author='cipres',
    keywords=['gemini', 'gempub'],
    packages=['gemgemgem', 'gemgemgem.ui'],
    install_requires=[
        'attrs',
        'DoubleLinkedList',
        'ebooklib',
        'ignition-gemini',
        'ipfshttpclient',
        'md2gemini @ git+https://github.com/pinnaculum/md2gemini#egg=md2gemini',
        'markdownify',
        'python-dateutil',
        'trimgmi',
        'yarl'
    ],
    extras_require={
        'ui': [
            'kivy'
        ]
    },
    package_data={
        '': [
            '*.kv'
        ]
    },
    license='MIT',
    entry_points={
        'gui_scripts': [
            'gemv = gemgemgem.ui:run_gempubv'
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
