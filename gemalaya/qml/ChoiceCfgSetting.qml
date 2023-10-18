import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.4

RowLayout {
  property string dotPath
  property string description
  property var choices

  property alias text: box.displayText

  signal changed(string chosen)

  Text {
    text: description
    font.pointSize: 14
    Layout.fillWidth: true
  }

  ComboBox {
    id: box
    model: choices
    displayText: Conf.get(dotPath)
    Layout.minimumWidth: 200
    Layout.minimumHeight: 32
    font.pointSize: 16
    onActivated: {
      Conf.set(dotPath, currentText)
      displayText = Conf.get(dotPath)

      changed(displayText)
    }
  }
}
