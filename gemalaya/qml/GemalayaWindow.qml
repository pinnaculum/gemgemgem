import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.4
import QtQuick.Window 2.2

import "."

Window {
  id: window
  visible: true
  title: 'Gemalaya'
  visibility: Window.Maximized

  property url initUrl

  Component.onCompleted: {
    if (initUrl != '') {
      stackl.gspace0.startUrl = initUrl
    }
  }

  GemSpaceCreateAction {
    stackLayout: stackl
  }
  GemSpaceCycleAction {
    stackLayout: stackl
  }
  GemSpacePreviousAction {
    stackLayout: stackl
  }
  GemSpaceNextAction {
    stackLayout: stackl
  }
  GemSpaceDestroyAction {
    stackLayout: stackl
  }

  Action {
    id: openTargetAction
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
