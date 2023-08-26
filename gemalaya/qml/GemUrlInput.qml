import QtQuick 2.14
import QtQuick.Controls 2.11

TextInput {
  id: control
  font.pointSize: Conf.theme.url.fontSize ? Conf.theme.url.fontSize : 16
  font.family: Conf.theme.url.fontFamily ? Conf.theme.url.fontFamily : 'Courier'
  color: Conf.theme.url.textColor
  selectionColor: Conf.theme.url.selectionColor
  selectedTextColor: Conf.theme.url.selectedTextColor
  wrapMode: Text.WrapAnywhere
  cursorDelegate: Rectangle {
    id: cursor
    visible: false
    color: Conf.theme.url.cursorColor ? Conf.theme.url.cursorColor : 'white'
    width: Conf.theme.url.cursorWidth ? Conf.theme.url.cursorWidth : 4
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

      PropertyAction {
        target: cursor
        property: 'color'
        value: Conf.theme.url.cursorColor1 ? Conf.theme.url.cursorColor1 : 'white'
      }

      PauseAnimation {
        duration: Conf.theme.url.cursorBlinkT1 ? Conf.theme.url.cursorBlinkT1 : 800
      }

      PropertyAction {
        target: cursor
        property: 'color'
        value: Conf.theme.url.cursorColor2 ? Conf.theme.url.cursorColor2 : 'white'
      }

      PauseAnimation {
        duration: Conf.theme.url.cursorBlinkT2 ? Conf.theme.url.cursorBlinkT2 : 100
      }

      PropertyAction {
        target: cursor
        property: 'visible'
        value: false
      }

      PauseAnimation {
        duration: Conf.theme.url.cursorBlinkT3 ? Conf.theme.url.cursorBlinkT3 : 800
      }

      onStopped: {
        cursor.visible = false
      }
    }
  }
}
