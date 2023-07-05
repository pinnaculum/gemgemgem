from yarl import URL

from typing import Union
from attrs import define, asdict
from DoubleLinkedList import DLinked

import re
import ignition
import tempfile
import traceback
import zipfile
import shutil
import urllib.request
from pathlib import Path
import os.path

from trimgmi import Document as GmiDocument
from trimgmi import LineType as GmiLineType

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
    index: str = 'index.gmi'
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
                 location: Union[URL, Path] = None,
                 zip_path: Path = None,
                 zipfile: zipfile.ZipFile = None):
        self.workdir = workdir if workdir else Path(tempfile.mkdtemp())
        self.location = location
        self.metadata = metadata if metadata else GemPubMetadata()
        self.zip_path = zip_path

        self._index_links = {}

    @property
    def m(self):
        return asdict(self.metadata)

    @property
    def toc(self):
        return self.get_toc()

    @property
    def index_path(self) -> str:
        # Return the path of the index file in the gempub
        return self.m.get('index', 'index.gmi')

    @property
    def index_path_basedir(self) -> str:
        # Return the directory name of the index file
        return os.path.dirname(self.index_path)

    def read_doc(self, path: str) -> bytes:
        # Read a document in the gempub and return its raw data

        if self.index_path_basedir and not \
                path.startswith(self.index_path_basedir + '/'):
            # The index's path in the gempub is in a subdirectory
            # Load the document from that directory
            zpath = os.path.join(self.index_path_basedir, path)
        else:
            zpath = path

        try:
            with zipfile.ZipFile(str(self.zip_path), 'r') as zip:
                with zip.open(zpath, 'r') as f:
                    return f.read()
        except Exception:
            return None

    def extract_item(self, path: str) -> Path:
        # Read a document in the gempub and write its data to a temporary file
        try:
            with tempfile.NamedTemporaryFile(delete=False,
                                             suffix=os.path.splitext(path)[1],
                                             mode='wb') as tf:
                with zipfile.ZipFile(str(self.zip_path), 'r') as zip:
                    with zip.open(path, 'r') as f:
                        tf.write(f.read())

            return Path(tf.name)
        except Exception:
            return None

    def index(self) -> bytes:
        # Return the book's index document

        return self.read_doc(self.m.get('index', 'index.gmi'))

    def get_toc(self):
        toc = DLinked.Linked()
        doc = GmiDocument()
        idx = self.index()

        if not idx:
            return

        [doc.append(line) for line in idx.decode().split('\n')]

        for line in doc.emit_line_objects(auto_tidy=True):
            if line.type == GmiLineType.LINK:
                toc.pushback(
                    (line.extra, line.text if line.text else line.extra)
                )

        return toc

    def ref(self, path: str, title: str = None):
        if path not in self._index_links:
            self._index_links[path] = title if title else path

    def from_toc(self, toc):
        for item in toc:
            if not item[0]:
                continue

            self.ref(item[0], item[1])

    def z(self):
        return zipfile.ZipFile(str(self.zip_path), 'r')

    def coverFrom(self, path: Path) -> None:
        """
        Copy the image from path and use it as the cover for this gempub
        """
        shutil.copy(str(path), str(self.workdir))
        self.metadata.cover = path.name

    def add(self, subpath: str, data, title: str = None) -> None:
        """
        Add a file in the gempub
        """
        mode = 'w+t' if isinstance(data, str) else 'wb'
        dst = self.workdir.joinpath(os.path.dirname(subpath))
        dst.mkdir(parents=True, exist_ok=True)

        with open(self.workdir.joinpath(subpath), mode) as fd:
            fd.write(data)

        if title:
            self.ref(subpath, title)

    def write(self, path: Path) -> bool:
        """
        Write the gempub to the given path
        """
        with open(self.workdir.joinpath('metadata.txt'), 'w+t') as m:
            for k, v in asdict(self.metadata).items():
                if not v:
                    continue

                m.write(f'{k}: {v}\n')

        with open(self.workdir.joinpath('index.gmi'), 'w+t') as i:
            for p, n in self._index_links.items():
                i.write(f'=> {p}    {n}\n\n')

        with zipfile.ZipFile(str(path), 'w',
                             zipfile.ZIP_DEFLATED) as zipf:
            for fp in self.workdir.glob("**/*"):
                zipf.write(fp, arcname=fp.relative_to(self.workdir))

        self.zip_path = path

        return True

    def pull(self, url: URL, title: str = None):
        rlpath = gget(url, self.workdir)

        if title:
            self.ref(rlpath, title)

    def __enter__(self):
        return self

    def __exit__(self, *args):
        return self


def load(path: Path,
         location: Union[URL, Path] = None):
    exp = Path(tempfile.mkdtemp())

    with zipfile.ZipFile(path, 'r') as zip:
        with zip.open('metadata.txt', 'r') as meta:
            metadata = metadata_as_dict(meta.read().decode())
            if not metadata:
                raise ValueError('invalid gempub')

        try:
            meta = GemPubMetadata(**metadata)
        except TypeError:
            raise

        return GemPubArchive(exp,
                             meta,
                             location=location if location else path,
                             zip_path=path)


def get(url: URL, ipfs_client=None):
    """
    Fetch a gempub from the given url
    """
    if url.scheme == 'dweb' and ipfs_client:
        data = ipfs_client.cat(url.path)
    elif url.scheme == 'ipfs' and ipfs_client:
        data = ipfs_client.cat(f'/ipfs/{url.host}/{url.path}')
    elif url.scheme == 'gemini':
        response = ignition.request(str(url))

        if not response.success():
            return None

        data = response.data()
    elif url.scheme in ['http', 'https']:
        with urllib.request.urlopen(str(url)) as f:
            data = f.read()
    else:
        return None

    try:
        assert data

        with tempfile.NamedTemporaryFile(suffix='.gpub',
                                         delete=False,
                                         mode='wb') as gpf:
            gpf.write(data)

        return load(gpf.name, location=url)
    except Exception:
        traceback.print_exc()


def create():
    return GemPubArchive()
