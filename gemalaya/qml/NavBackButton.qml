import QtQuick 2.2
import QtQuick.Controls 2.15

ToolButton {
  id: button
  icon.source: Conf.themeRsc('arrow-back.png')
  icon.width: 32
  icon.height: 32
  icon.color: icolor
  enabled: false

  property string icolor: button.enabled ? 'transparent' : 'gray'

  ScaleAnim {
    id: anim
    targetItem: button
  }

  action: Action {
    shortcut: Conf.shortcuts.historyBack
    enabled: button.visible
    onTriggered: anim.running = true
  }
}
