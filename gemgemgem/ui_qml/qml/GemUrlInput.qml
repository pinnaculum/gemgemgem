import QtQuick 2.14
import QtQuick.Controls 2.11

TextInput {
  id: control
  font.pointSize: 18
  font.family: "Segoe UI"
  color: "white"
  selectionColor: "#21be2b"
  selectedTextColor: "#ffffff"
  focus: true
  cursorDelegate: Rectangle {
    id: cursor
    visible: false
    color: "cornsilk"
    width: 16
    property int vpad: 4

    onYChanged: y = control.cursorRectangle.y - (vpad / 2)
    onHeightChanged: height = control.cursorRectangle.height + vpad

    SequentialAnimation {
      loops: Animation.Infinite
      running: control.cursorVisible

      PropertyAction {
        target: cursor
        property: 'visible'
        value: true
      }

      PauseAnimation {
        duration: 400
      }

      PropertyAction {
        target: cursor
        property: 'visible'
        value: false
      }

      PauseAnimation {
        duration: 400
      }

      onStopped: {
        cursor.visible = false
      }
    }
  }
}
