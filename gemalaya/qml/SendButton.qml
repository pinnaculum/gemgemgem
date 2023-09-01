import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.4

ToolButton {
  id: send
  text: qsTr('Send')
  icon.source: Conf.themeRsc('input-send.png')
  icon.width: 32
  icon.height: 32
  font.pointSize: 22
  Keys.onReturnPressed: clicked()

  background: Rectangle {
    implicitWidth: 140
    implicitHeight: 50
    color: parent.focus ? "lightgreen" : "lightsteelblue"
    border.color: parent.focus ? 'black' : '#26282a'
    border.width: parent.focus ? 2 : 1
    radius: 8
  }
}
