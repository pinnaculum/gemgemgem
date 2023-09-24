import QtQuick 2.2
import QtQuick.Controls 2.15

ToolButton {
  id: control
  icon.width: 32
  icon.height: 32
  font.pointSize: 16
  Keys.onReturnPressed: clicked()
  display: AbstractButton.TextBesideIcon
  property alias anim: anim

  SequentialAnimation {
    id: anim

    PropertyAnimation {
      target: bg
      property: 'color'
      to: Conf.links.openAnim.buttonBgColor
      duration: 100
    }
    PropertyAnimation {
      target: bg
      property: 'border.color'
      to: 'darkorange'
      duration: 100
    }
  }

  background: Rectangle {
    id: bg
    implicitWidth: 220
    implicitHeight: 50
    color: (parent.down || parent.pressed) ? "lightblue" : "lightsteelblue"
    border.color: parent.focus ? 'black' : '#26282a'
    border.width: parent.focus ? 2 : 1
    radius: 8
  }
}
