import argparse

from .gempubv import ViewerApp


def run_gempubv():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--library-path',
        dest='libpath',
        help='Gempub embedded library path',
        default=None
    )

    parser.add_argument('ebook', nargs='?')

    ViewerApp(parser.parse_args()).run()
