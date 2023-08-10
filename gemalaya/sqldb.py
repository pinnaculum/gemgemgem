from PySide6.QtCore import Qt
from PySide6.QtCore import Slot

from PySide6.QtSql import QSqlDatabase
from PySide6.QtSql import QSqlQuery
from PySide6.QtSql import QSqlTableModel

from PySide6.QtQml import QmlElement


QML_IMPORT_NAME = "Gemalaya"
QML_IMPORT_MAJOR_VERSION = 1


def add_bookmark(url: str, title: str):
    query = QSqlQuery()
    query.exec("""
        INSERT INTO bookmarks(
            title,
            url
        )
        VALUES(?, ?)
    """)
    query.addBindValue(title)
    query.addBindValue(url)
    query.exec()


def create_db(path: str):
    db = QSqlDatabase.addDatabase("QSQLITE")
    db.setDatabaseName(path)
    db.open()

    createTableQuery = QSqlQuery()
    createTableQuery.exec("""
        CREATE TABLE bookmarks (
            title VARCHAR(256) PRIMARY KEY NOT NULL,
            url VARCHAR(256) NOT NULL
        )
    """)

    add_bookmark('station', 'gemini://station.martinrue.com')
    add_bookmark('local', 'gemini://localhost/')

    db.commit()

    return db


@QmlElement
class BookmarksTableModel(QSqlTableModel):
    @Slot(str)
    def findSome(self, query: str):
        self.setFilter(f'title LIKE "%{query}%"')
        self.select()

    @Slot(str, str)
    def addBookmark(self, url: str, title: str):
        add_bookmark(url, title)
        self.select()

    @Slot(int, result=list)
    def getFromRow(self, row: int):
        try:
            rec = self.record(row)
            return [rec.value(i) for i in range(0, rec.count())]
        except Exception:
            return []

    def roleNames2(self):
        names = {}
        # names[hash(Qt.UserRole)] = 'url'.encode()
        names[Qt.UserRole] = 'url'.encode()
        # names[hash(Qt.UserRole + 1)] = 'title'.encode()
        return names

    def data2(self, index, role):
        if role < Qt.UserRole:
            return QSqlTableModel.data(self, index, role)

        sr = self.record(index.row())
        return sr.value(role - Qt.UserRole)
