from yarl import URL

from attrs import define, asdict

import re
import ignition
import tempfile
import traceback
import zipfile
import shutil
from pathlib import Path

from . import gget


def metadata_as_dict(data: str) -> dict:
    allowed = list(asdict(GemPubMetadata()).keys())

    meta = {}
    for line in data.split('\n'):
        if not line:
            continue

        splitted = re.split(':', line.strip(), 1)
        if splitted and splitted[0] in allowed:
            meta[splitted[0]] = splitted[1].lstrip()

    return meta


@define(auto_attribs=True)
class GemPubMetadata:
    title: str = 'No title'
    author: str = ''
    version: str = ''
    description: str = ''
    revisionDate: str = ''
    index: str = ''
    charset: str = 'UTF-8'
    cover: str = ''
    copyright: str = ''
    language: str = ''
    license: str = ''
    publishDate: str = ''
    published: str = ''
    gempubVersion: str = '1.0.0'
    gpubVersion: str = '1.0.0'
    version: str = ''


class GemPubArchive:
    def __init__(self,
                 workdir: Path = None,
                 metadata=None,
                 url: URL = None,
                 zip_path: Path = None,
                 zipfile: zipfile.ZipFile = None):
        self.workdir = workdir if workdir else Path(tempfile.mkdtemp())
        self.url = url
        self.metadata = metadata if metadata else GemPubMetadata()
        self.zip = zipfile
        self.zip_path = zip_path

        self._index_links = {}

    @property
    def m(self):
        return asdict(self.metadata)

    def z(self):
        return zipfile.ZipFile(str(self.zip_path), 'r')

    def coverFrom(self, path: Path):
        shutil.copy(str(path), str(self.workdir))
        self.metadata.cover = path.name

    def write(self, path: Path):
        """
        Write the gempub to the given path
        """
        with open(self.workdir.joinpath('metadata.txt'), 'w+t') as m:
            for k, v in asdict(self.metadata).items():
                if not v:
                    continue

                m.write(f'{k}: {v}\n')

        with open(self.workdir.joinpath('index.gmi'), 'w+t') as i:
            for n, p in self._index_links.items():
                i.write(f'=> {p}    {n}\n\n')

        with zipfile.ZipFile(str(path), 'w',
                             zipfile.ZIP_DEFLATED) as zipf:
            for fp in self.workdir.glob("**/*"):
                zipf.write(fp, arcname=fp.relative_to(self.workdir))

    def pull(self, url: URL, title: str = None):
        rlpath = gget(url, self.workdir)

        if title:
            self._index_links[title] = rlpath

    def __enter__(self):
        return self

    def __exit__(self, *args):
        return self


def get(url: URL, ipfs_client=None):
    metadata = None

    if url.scheme == 'dweb' and ipfs_client:
        print('getting from ipfs')
        data = ipfs_client.cat(url.path)
    elif url.scheme == 'ipfs' and ipfs_client:
        p = f'/ipfs/{url.host}/{url.path}'
        print('getting from ipfs', p)
        data = ipfs_client.cat(p)
    else:
        response = ignition.request(str(url))

        if not response.success():
            return None

        data = response.data()

    try:
        exp = Path(tempfile.mkdtemp())
        with tempfile.NamedTemporaryFile(suffix='.zip',
                                         delete=False,
                                         mode='wb') as gpf:
            gpf.write(data)

        with zipfile.ZipFile(gpf.name, 'r') as zip:
            zip.extractall(str(exp))

            with zip.open('metadata.txt', 'r') as meta:
                metadata = metadata_as_dict(meta.read().decode())
                if not metadata:
                    raise ValueError(f'{url}: invalid gempub')

            try:
                meta = GemPubMetadata(**metadata)
            except TypeError:
                raise

            return GemPubArchive(exp, meta,
                                 url=url, zipfile=zip,
                                 zip_path=Path(gpf.name))
    except Exception:
        traceback.print_exc()


def create():
    return GemPubArchive()
