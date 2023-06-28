from setuptools import setup


setup(
    name='gemgemgem',
    version='0.1.0',
    description='Some tools to work with gemini and gempub',
    url='https://gitlab.com/galacteek/gemgemgem',
    author='cipres',
    keywords=['gemini', 'gempub'],
    packages=['gemgemgem'],
    install_requires=[
        'ignition-gemini',
        'trimgmi',
        'ipfshttpclient',
    ],
    license='MIT',
    classifiers=[
        'Development Status :: 4 - Beta',
        'Environment :: Console',
        'Intended Audience :: Developers',
        'Intended Audience :: System Administrators',
        'License :: OSI Approved :: MIT License',
        'Operating System :: OS Independent',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8'
    ]
)
