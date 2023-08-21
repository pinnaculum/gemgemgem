import argparse
import re
import os.path
import sys
import traceback

from dateutil import parser
from markdownify import markdownify
from md2gemini import md2gemini
from omegaconf import OmegaConf
from datetime import datetime
from yarl import URL

from ebooklib.utils import parse_html_string
from pathlib import Path

from lxml import etree
import ebooklib
import ipfshttpclient
from ebooklib import epub

from gemgemgem import gempub


def html2gem(html: str) -> tuple:
    """
    Transform some HTML code to gemtext
    """
    lines = [line for line in html.split("\n") if not line.startswith('<?xml')]

    md = markdownify('\n'.join(lines),
                     heading_style='ATX',
                     strip=['script', 'style'])
    try:
        return md2gemini(md, links='copy',
                         md_links=True,
                         geminize_html_links=True), None
    except Exception:
        # md2gemini will fail and produce an exception when it
        # generates an empty gemtext document
        traceback.print_exc()
        return None, None


def gmin(name: str) -> str:
    return name.replace('.html', '.gmi').replace('.xhtml', '.gmi')


def parse_epub_nav(xml, auto_gaps=True):
    root = etree.fromstring(xml)

    for appt in root.getchildren():
        prevPageNo, pageNo = None, None
        for elem in appt.getchildren():

            for child in elem.getchildren():
                srcTag = ''

                if ("content" in child.tag):
                    srcTag = child.get("src")

                    if '#' in srcTag:
                        srcTag = srcTag.split('#')[0]

                    # Fill the gaps in the index by guessing
                    # from the page numbers
                    ma = re.search(r'^(.*?)(\d+)\.([\w]+)', srcTag)
                    if ma and auto_gaps:
                        pageNo = int(ma.group(2))
                        digitsn = len(ma.group(2))

                        if prevPageNo and pageNo:
                            if (pageNo - prevPageNo) > 1:
                                for i in range(prevPageNo, pageNo + 1):
                                    n = f"%0{digitsn}d" % i
                                    yield f'{ma.group(1)}{n}.gmi', f'Page {i}'

                        prevPageNo = pageNo

                for node in child.getchildren():
                    if node.text:
                        text = node.text

                yield gmin(srcTag), text


def parse_epub_toc(xml: str):
    html_node = parse_html_string(xml)

    nav_node = html_node.xpath("//nav[@*='toc']")[0]

    def walk(node):
        for item_node in node.findall('li'):
            for ol_node in item_node.findall('ol'):
                yield from walk(ol_node)

            for link_node in item_node.findall('a'):
                href = link_node.get('href')
                title = " ".join([t.strip() for t in link_node.itertext()])

                yield gmin(href), title

    for ol_node in nav_node.findall('ol'):
        yield from walk(ol_node)


def gempubify_file(src: Path,
                   dst: Path = None,
                   ipfsapi_maddr: str = None,
                   ipfsout: bool = False) -> gempub.GemPubArchive:
    """
    Transform something (for now only epubs supported) to a gempub archive
    """

    def meta(bk, attr: str) -> str:
        try:
            return bk.get_metadata('DC', attr).pop()[0]
        except Exception as err:
            print(f'Failed to get metadata {attr} from epub: {src}: {err}',
                  file=sys.stderr)
            return ''

    if not dst:
        dst = Path(src.with_suffix('.gpub'))

    try:
        book = epub.read_epub(str(src), options={'ignore_ncx': True})

        with gempub.create() as gp:
            nav = None
            toc = []
            gp.metadata.title = meta(book, 'title')
            gp.metadata.author = meta(book, 'author')
            gp.metadata.language = meta(book, 'language')

            try:
                date = parser.parse(meta(book, 'date'))
            except Exception:
                pass
            else:
                gp.metadata.publishDate = date.strftime('%Y-%m-%d')

            for item in book.get_items():
                itype = item.get_type()
                name = item.get_name()
                content = item.get_content()

                if itype == ebooklib.ITEM_NAVIGATION:
                    navXml = etree.XML(content)
                    nav = list(parse_epub_nav(etree.tostring(navXml)))
                elif itype == ebooklib.ITEM_IMAGE:
                    gp.add(name, content)
                    if name.startswith('cover'):
                        gp.metadata.cover = name
                elif itype == ebooklib.ITEM_COVER:
                    gp.add(name, content)
                    gp.metadata.cover = name
                elif itype == ebooklib.ITEM_DOCUMENT:
                    gemt, _title = html2gem(content.decode())
                    if not gemt:
                        # Conversion failed or empty document: non-fatal
                        print(f'Error converting document {name} (skipping)',
                              file=sys.stderr)
                        continue

                    gp.add(gmin(name), gemt)

                    if os.path.basename(name).startswith('toc'):
                        navXml = etree.XML(content)
                        toc = list(parse_epub_toc(etree.tostring(navXml)))

            if toc or nav:
                gp.from_toc(toc if toc else nav)

            gp.write(dst)

        if ipfsout:
            try:
                ipfs_client = ipfshttpclient.Client(ipfsapi_maddr)
                entries = ipfs_client.add(
                    str(dst),
                    cid_version=1,
                    wrap_with_directory=True
                )
                assert entries

                print(entries[-1]['Hash'])
            except Exception:
                raise

        return gp, dst
    except Exception as e:
        raise e


def gempubify_project(projp: Path,
                      dst_gempub_path: Path = None) -> Path:
    """
    Create a gempub from a gemgemgem YAML project file.
    """
    now = datetime.now()

    try:
        with open(projp, 'rt') as y:
            cfg = OmegaConf.load(y)

        with gempub.create() as gp:
            cover_fn = cfg.get('cover', None)
            cover_path = projp.parent.joinpath(cover_fn) if cover_fn else None

            if cover_path and cover_path.is_file():
                gp.coverFrom(cover_path)

            gp.metadata.title = cfg.title
            gp.metadata.author = cfg.author
            gp.metadata.description = cfg.get('description', 'No description')
            gp.metadata.publishDate = now.strftime('%Y-%m-%d')

            for entry in cfg.spine:
                content = entry.get('content', None)
                title = entry.get('title', None)
                path = entry.get('path', None)
                url = entry.get('url', None)

                if isinstance(content, str):
                    gp.add(path, content, title=title)
                elif url:
                    gp.pull(URL(url), entry.title)

        dst = dst_gempub_path if dst_gempub_path else \
            projp.parent.joinpath(
                f'{cfg.gpubname}_{gp.metadata.publishDate}.gpub')

        gp.write(dst)

        return dst
    except Exception:
        raise


def gempubify():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--output',
        '-o',
        dest='dst',
        help='Output file path',
        default=None
    )
    parser.add_argument(
        '--ipfs-import',
        dest='ipfsout',
        action='store_true',
        default=False,
        help='Import the generated gempub archive to IPFS'
    )
    parser.add_argument(
        '--ipfs-maddr',
        '-m',
        dest='ipfsapi_maddr',
        default='/ip4/127.0.0.1/tcp/5001',
        help='Use a specific IPFS daemon multiaddr'
    )

    parser.add_argument('src')

    args = parser.parse_args()

    srcp = Path(args.src)
    dstp = Path(args.dst) if args.dst else None

    if srcp.name.endswith('.yaml'):
        # Create a gempub from a project file
        gempubify_project(srcp,
                          dst_gempub_path=dstp)
    else:
        gempubify_file(srcp,
                       dst=dstp,
                       ipfsapi_maddr=args.ipfsapi_maddr,
                       ipfsout=args.ipfsout)
