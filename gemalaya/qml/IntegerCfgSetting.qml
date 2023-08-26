import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.4

RowLayout {
  property string dotPath
  property string name
  property string description

  property alias spin: spinbox

  Text {
    text: description
    Layout.fillWidth: true
    font.pointSize: 14
  }

  SpinBox {
    id: spinbox
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.minimumWidth: parent.width * 0.25
    Layout.maximumWidth: parent.width * 0.25
    font.pointSize: 14
    from: -32768
    to: 32768
    editable: true
    value: Conf.get(dotPath)
    onValueModified: {
      Conf.set(dotPath, value)
    }
  }
}
