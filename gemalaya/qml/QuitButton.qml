import QtQuick 2.2
import QtQuick.Controls 2.15

ToolButton {
  id: button
  icon.source: Conf.themeRsc('quit.png')
  icon.width: 32
  icon.height: 32

  action: Action {
    shortcut: Conf.shortcuts.quit
    enabled: button.visible
  }
}
