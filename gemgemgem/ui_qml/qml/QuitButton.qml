import QtQuick 2.2
import QtQuick.Controls 2.15

ToolButton {
  icon.source: 'qrc:/share/icons/quit.png'
  icon.width: 32
  icon.height: 32

  Shortcut {
    sequence: 'F12'
    onActivated: clicked()
  }
}
