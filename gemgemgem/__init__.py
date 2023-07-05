from yarl import URL
from pathlib import Path

import ignition
import tempfile
import re
import os.path
import traceback

from trimgmi import Document as GmiDocument
from trimgmi import LineType as GmiLineType


def down(url: URL):
    response = ignition.request(str(url))

    if not response.success():
        return

    with tempfile.NamedTemporaryFile(delete=False) as dstf:
        dstf.write(response.data())

    return Path(dstf.name)


def gget(url: URL, basedir: Path, handled: list = [],
         depth: int = 0,
         maxdepth: int = 10,
         referer: URL = None):
    # Kind of like a terrible, terrible wget -r for gemini

    home = basedir.joinpath(url.host)
    dstd = home.joinpath(os.path.dirname(url.path).lstrip('/'))

    if url.name and url.path.endswith('/'):
        path = dstd.joinpath('index.gmi')
    else:
        ext = os.path.splitext(url.name)[1] if url.name else None

        if not ext:
            path = dstd.joinpath(
                f'{url.name}.gmi' if url.name else 'index.gmi')
        else:
            path = dstd.joinpath(url.name)

    if path.is_file():
        return

    if not dstd.exists():
        dstd.mkdir(parents=True, exist_ok=True)

    response = ignition.request(str(url))

    if not response.success():
        return

    try:
        maxl = None
        raw = response.data()

        if isinstance(raw, bytes):
            # binary
            with open(str(path), 'wb') as fd:
                fd.write(raw)

            handled.append(str(url))
            return path.relative_to(basedir)

        with open(str(path), 'wt') as fd:
            doc = GmiDocument()
            doc_r = GmiDocument()

            for line in raw.split('\n'):
                doc.append(line)

            for line in doc.emit_line_objects(auto_tidy=True):
                if line.type == GmiLineType.LINK:
                    if line.extra.startswith('/'):
                        surl = url.with_path(line.extra)
                    else:
                        surl = URL(line.extra)

                    if not surl.scheme:
                        # relative to current url
                        surl = url.with_path(url.path + '/' + line.extra)

                    ext = os.path.splitext(surl.name)[1] if surl.name else None

                    if line.extra.startswith('/'):
                        # XXX: rewrite to relative URL if it starts with /
                        # '/' = gempub root
                        line.extra = re.sub('/', './', line.extra, count=1)

                    doc_r._lines.append(line)

                    if surl == referer:
                        continue

                    if surl.host and surl.host != url.host:
                        # Limited to one gemini domain
                        continue

                    if maxl and len(handled) > maxl:
                        continue

                    if str(surl) in handled:
                        continue

                    if ext in ['.gpub']:
                        gget(surl, basedir, handled, referer=url,
                             depth=depth, maxdepth=maxdepth)
                        handled.append(str(surl))

                    elif surl.scheme == 'gemini':
                        depth += 1

                        if depth < maxdepth:
                            gget(surl, basedir, handled, referer=url,
                                 depth=depth, maxdepth=maxdepth)

                        handled.append(str(surl))

                else:
                    doc_r._lines.append(line)

            fd.write('\n'.join(list(doc_r.emit_trim_gmi())))
    except Exception:
        traceback.print_exc()

    handled.append(str(url))
    return path.relative_to(basedir)
