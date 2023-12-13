import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.4
import QtQuick.Window 2.2
import QtQuick.Dialogs

import "."

Window {
  id: window
  visible: true
  title: 'Gemalaya'
  visibility: Window.Maximized

  property url initUrl

  MessageDialog {
    id: updatedMessage
    text: qsTr("Gemala was updated successfully")
    informativeText: qsTr("Restart the application to use the latest version")
    buttons: MessageDialog.Ok
  }

  Connections {
    target: gemalaya

    function onUpdateInstalled() {
      updatedMessage.open()
    }

    function onUpdateAvailable(version, wheelUrl) {
      /* There's an update available */
      console.log('New gemalaya version available: ' + version)

      var component = Qt.createComponent('GemalayaUpdatePopup.qml')
      var item = component.createObject(window, {
        version: version,
        wheelUrl: wheelUrl,
        width: window.width * 0.7,
        height: window.width * 0.25,
      })
      item.open()
      item.forceActiveFocus()
    }
  }

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

  /* Stack save/load actions (1) */
  StackSaveAction {
    stackLayout: stackl
    shortcut: Conf.stackShortcuts.stackSave1
    index: 1
  }
  StackLoadFromCfgAction {
    stackLayout: stackl
    shortcut: Conf.stackShortcuts.stackLoad1
    index: 1
  }

  /* Stack save/load actions (2) */
  StackSaveAction {
    stackLayout: stackl
    shortcut: Conf.stackShortcuts.stackSave2
    index: 2
  }
  StackLoadFromCfgAction {
    stackLayout: stackl
    shortcut: Conf.stackShortcuts.stackLoad2
    index: 2
  }

  /* Action to set where links in this page will be opened */
  Action {
    id: openTargetAction
    shortcut: Conf.shortcuts.linkOpenTargetSwitch

    onTriggered: {
      stackl.openInSwitch()
    }
  }

  /* Theme change popup */
  Popup {
    id: themeChangedPopup
    x: window.width * 0.25
    y: window.height * 0.5
    margins: 20

    property string message

    background: Rectangle {
      color: 'black'
      border.color: 'white'
      border.width: 2
      radius: 10
    }

    contentItem: Text {
      text: themeChangedPopup.message
      color: 'blue'
      font.family: 'Arial'
      font.pointSize: 40
    }
  }

  Scheduler {
    id: sched
  }

  /* Action to cycle between themes */
  Action {
    id: themesCycleAction
    shortcut: Conf.shortcuts.themesCycle

    onTriggered: {
      var nextTheme
      let ctidx = Conf.themesNames.indexOf(Conf.ui.theme)

      if ((ctidx + 1) <= Conf.themesNames.length - 1)
        nextTheme = Conf.themesNames[ctidx+1]
      else
        nextTheme = Conf.themesNames[0]

      Conf.changeTheme(nextTheme)

      themeChangedPopup.message = 'Current theme: ' + nextTheme
      themeChangedPopup.open()

      sched.delay(function() { themeChangedPopup.close() }, 1000)
    }
  }

  Action {
    shortcut: Conf.shortcuts.fontSizeIncrease
    onTriggered: {
      Conf.set('ui.fonts.defaultPointSize',
               Conf.fontPrefs.defaultPointSize + 1)
      Conf.set('ui.fonts.text.pointSize',
               Conf.fontPrefs.text.pointSize + 1)
      Conf.set('ui.fonts.links.pointSize',
               Conf.fontPrefs.links.pointSize + 1)
      Conf.update()
    }
  }
  Action {
    shortcut: Conf.shortcuts.fontSizeDecrease
    onTriggered: {
      Conf.set('ui.fonts.defaultPointSize',
               Conf.fontPrefs.defaultPointSize - 1)
      Conf.set('ui.fonts.text.pointSize',
               Conf.fontPrefs.text.pointSize - 1)
      Conf.set('ui.fonts.links.pointSize',
               Conf.fontPrefs.links.pointSize - 1)
      Conf.update()
    }
  }

  Action {
    shortcut: Conf.shortcuts.openLinkFromClipboard
    onTriggered: {
      var linkUrl = gemalaya.getClipboardUrl('auto')

      if (linkUrl && linkUrl.length > 0)
        stackl.spawn(linkUrl, true)
    }
  }

  GemStackLayout {
    id: stackl
    anchors.fill: parent
  }
}
