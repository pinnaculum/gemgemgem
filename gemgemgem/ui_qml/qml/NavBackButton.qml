import QtQuick 2.2
import QtQuick.Controls 2.15

ToolButton {
  icon.source: 'arrow-back.png'
  icon.width: 32
  icon.height: 32

  Shortcut {
    sequence: 'Ctrl+Backspace'
    onActivated: clicked()
  }
}
