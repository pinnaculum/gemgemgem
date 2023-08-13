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

  SequentialAnimation {
    id: anim

    ScaleAnimator {
      target: button
      from: 1
      to: 1.4
      duration: 300
    }
    PauseAnimation {
      duration: 300
    }
    ScaleAnimator {
      target: button
      to: 1
      duration: 100
    }
  }

  action: Action {
    shortcut: Conf.shortcuts.historyBack
    enabled: button.visible
    onTriggered: anim.running = true
  }
}
