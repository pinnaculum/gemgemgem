import QtQuick 2.2
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.4

GridLayout {
  objectName: 'linksGroupItem'
  flow: GridLayout.LeftToRight
  layoutDirection: Qt.LeftToRight
  columns: Conf.ui.links.gridColumns
  rowSpacing: Conf.ui.links.gridRowSpacing

  signal linkClicked(string baseUrl, string href)

  function keybSeqLookup(seq) {
    var item

    for (var i=0; i < children.length; i++) {
      item = children[i]

      if (item.keybAccessSeq === seq) {
        return item
      }
    }

    return null
  }
}
