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
               Conf.fontPrefs.defaultPointSize + 2)
      Conf.set('ui.fonts.text.pointSize',
               Conf.fontPrefs.text.pointSize + 2)
      Conf.set('ui.fonts.links.pointSize',
               Conf.fontPrefs.links.pointSize + 2)
      Conf.update()
    }
  }
  Action {
    shortcut: Conf.shortcuts.fontSizeDecrease
    onTriggered: {
      Conf.set('ui.fonts.defaultPointSize',
               Conf.fontPrefs.defaultPointSize - 2)
      Conf.set('ui.fonts.text.pointSize',
               Conf.fontPrefs.text.pointSize - 2)
      Conf.set('ui.fonts.links.pointSize',
               Conf.fontPrefs.links.pointSize - 2)
      Conf.update()
    }
  }

  ColumnLayout {
    anchors.fill: parent

    GemStackLayout {
      id: stackl
    }
  }
}
