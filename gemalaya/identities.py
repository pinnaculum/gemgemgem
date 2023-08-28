from pathlib import Path

from gemgemgem.x509 import x509SelfSignedGenerate


class IdentitiesManager:
    def __init__(self, idents_path: Path):
        self.identities_path = idents_path

    def ident_paths(self, name: str):
        p = self.identities_path.joinpath(name)
        p.mkdir(parents=True, exist_ok=True)
        certp = p.joinpath('cert.crt')
        keyp = p.joinpath('cert.key')
        return (p, certp, keyp)

    def create(self, ident_name: str,
               commonName: str = 'gemalaya.gitlab.io'):
        dir, certp, keyp = self.ident_paths(ident_name)

        x509SelfSignedGenerate(commonName,
                               keyDestPath=keyp,
                               certDestPath=certp)

        return (dir, certp, keyp)
