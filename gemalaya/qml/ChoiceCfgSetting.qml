import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.4

RowLayout {
  property string dotPath
  property string description
  property var choices

  Text {
    text: description
    font.pointSize: 14
    Layout.fillWidth: true
  }

  ComboBox {
    model: choices
    displayText: Conf.get(dotPath)
    Layout.minimumWidth: 200
    Layout.minimumHeight: 32
    font.pointSize: 16
    onActivated: {
      Conf.set(dotPath, currentText)
    }
  }
}
