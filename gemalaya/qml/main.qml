import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.4
import QtQuick.Window 2.2

import "."

Window {
  id: window
  visible: true

  GemSpaceCreateAction {
    stackLayout: stackl
  }
  GemSpaceCycleAction {
    stackLayout: stackl
  }
  GemSpaceDestroyAction {
    stackLayout: stackl
  }

  Action {
    id: openInTab
    shortcut: Conf.shortcuts.linkOpenTargetSwitch

    onTriggered: {
      stackl.openInSwitch()
    }
  }

  ColumnLayout {
    anchors.fill: parent

    GemStackLayout {
      id: stackl
    }
  }
}
