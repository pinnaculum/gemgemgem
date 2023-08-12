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
            url,
            title
        )
        VALUES(?, ?)
    """)

    query.addBindValue(url)
    query.addBindValue(title)
    query.exec()


def create_db(path: str):
    db = QSqlDatabase.addDatabase("QSQLITE")
    db.setDatabaseName(path)
    db.open()

    createTableQuery = QSqlQuery()
    createTableQuery.exec("""
        CREATE TABLE bookmarks (
            url VARCHAR(256) PRIMARY KEY NOT NULL,
            title VARCHAR(256),
            shortcut VARCHAR(32),
            enabled BOOLEAN
        )
    """)

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
