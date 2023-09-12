import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.4

import "."

Rectangle {
  id: gemspace

  property StackLayout stackLayout
  property url startUrl

  /* Where to open pages */
  property int openIn: 0

  property alias currentUrl: addrc.url
  property alias addrc: addrc

  color: Conf.gemspace.bgColor

  function chSpaceSwitch() {
    if (StackLayout.isCurrentItem) {
      switch(openIn) {
        case 0:
          openIn = 1
          break
        case 1:
          openIn = 2
          break
        case 2:
          openIn = 0
          break
      }
    }
  }

  function onSpaceChanged(index) {
    if (StackLayout.index == stackLayout.currentIndex) {
      if (sview.page.empty) {
        addrc.focusInput()
      } else {
        /* Focus the first visible item in the page */
        sview.page.focusFirstVisibleItem()
      }

      gsIndexAnim.running = true
    }
  }

  function onSpaceClose(closeIndex) {
    if (StackLayout.index == stackLayout.currentIndex && StackLayout.index != 0) {
      gemspace.parent = null

      if (stackLayout.currentIndex > 0) {
        stackLayout.currentIndex -= 1
      }
    }
  }

  function close() {
    gemspace.parent = null

    if (stackLayout.currentIndex > 0) {
      stackLayout.currentIndex -= 1
    }
  }

  Component.onCompleted: {
    stackLayout.openInSwitch.connect(chSpaceSwitch)
    stackLayout.spaceChanged.connect(onSpaceChanged)

    if (startUrl.toString().length > 0) {
      /* In new space */
      sview.browse(startUrl, null)
    } else {
      /* Focus the address bar */
      sched.delay(function(){ addrc.focusInput()}, 100)
    }
  }

  ScaleAnim {
    id: gsIndexAnim
    targetItem: gsStackIndex
  }

  Scheduler {
    id: sched
  }

  Action {
    shortcut: Conf.shortcuts.bookmark
    enabled: gemspace.visible
    onTriggered: {
      if (addrc.url) {
        if (bookmarksModel.addBookmark(
          addrc.url,
          sview.pageTitle.length > 0 ? sview.pageTitle : "No title"
        ) == true) {
          addrc.animate()
        }
      }
    }
  }

  Action {
    shortcut: Conf.shortcuts.pageReload
    enabled: gemspace.visible
    onTriggered: {
      if (addrc.url) {
        sview.browse(addrc.url, null)
      }
    }
  }

  Action {
    shortcut: Conf.shortcuts.pageTextSearch
    enabled: gemspace.visible
    onTriggered: {
      if (sview.actionMode == sview.modes.SEARCH) {
        sview.page.searchText(sview.searchTextInput)
      } else {
        sview.actionMode = sview.modes.SEARCH
        sview.searchTextInput = ""
      }
    }
  }

  Action {
    id: appConfigureAction
    shortcut: Conf.shortcuts.openConfigDialog
    enabled: gemspace.visible
    onTriggered: {
      var component = Qt.createComponent('AppConfigurePopup.qml')
      var cpopup = component.createObject(gemspace, {
        width: gemspace.width * 0.9,
        height: gemspace.height * 0.9
      })

      cpopup.open()
      cpopup.forceActiveFocus()
    }
  }

  ColumnLayout {
    anchors.fill: parent

    RowLayout {
      Text {
        id: gsStackIndex
        text: gemspace.StackLayout.index
        color: Conf.gemspace.stackIndex.color
        font.pointSize: Conf.gemspace.stackIndex.fontSize
      }

      NavBackButton {
        id: backb
        enabled: false
        onClicked: {
          let u = addrc.histPop()

          if (u !== undefined) {
            sview.browse(u, null)
          }
        }
      }

      GemAddressCtrl {
        id: addrc

        onUnfocusRequest: {
          /* Escape pressed on the address bar */

          if (sview.page.empty == false) {
            /* Focus the page if there's something loaded */
            sview.page.forceActiveFocus()
          }
        }

        Layout.fillWidth: true

        KeyNavigation.backtab: sview
        KeyNavigation.tab: sview

        onHistorySizeChanged: {
          backb.enabled = hsize > 1
        }

        onRequested: {
          sview.browse(text, null)
        }
      }

      Rectangle {
        id: openType
        width: 32
        height: 32
        radius: 5
        color: 'transparent'
        border.color: ocolor
        border.width: 2

        property string ocolor: {
          if (openIn == 0) {
            return 'yellow'
          }
          if (openIn == 1) {
            return 'blue'
          }
          if (openIn == 2) {
            return 'red'
          }
        }

        Text {
          text: {
            switch(openIn) {
              case 0:
                return 'H'
              case 1:
                return 'T'
              case 2:
                return 'W'
            }
          }
          anchors.centerIn: parent
          font.pointSize: 18
          color: openType.ocolor
        }
      }

      ToolButton {
        icon.source: Conf.themeRsc('settings.png')
        icon.cache: true
        icon.width: 32
        icon.height: 32
        Layout.minimumWidth: 48
        onClicked: appConfigureAction.trigger()
        display: AbstractButton.IconOnly
      }

      ToolButton {
        id: dlQueueButton
        icon.source: Conf.themeRsc('download.png')
        icon.width: 32
        icon.height: 32
        visible: false
      }

      QuitButton {
        onClicked: gemalaya.quit()
        enabled: true
      }
    }

    GeminiPageView {
      id: sview
      addrController: addrc

      onKeybSequenceMatch: kSeqAnim.running = true

      onTextFound: textFoundAnim.running = true

      onLinkActivated: {
        if (openIn === 0) {
          /* Open in this gemspace */
          sview.browse(linkUrl.toString(), baseUrl)
        } else if (openIn === 1) {
          /* Open in new gemspace */
          let space = stackLayout.spawn(linkUrl, true)
        } else if (openIn === 2) {
          /* Open in new window */
          var component = Qt.createComponent('GemalayaWindow.qml')
          component.createObject(null, {initUrl: linkUrl})
        }
      }
    }

    Rectangle {
      id: seqRect
      anchors.margins: 8
      Layout.alignment: Qt.AlignRight
      color: '#F0F8FF'
      width: sview.width * 0.2
      height: 32
      visible: sview.linkSeqInput.length > 0 || kSeqAnim.running
      border.width: 1
      border.color: 'lightgray'
      radius: 2

      SequentialAnimation {
        id: kSeqAnim

        PropertyAnimation {
          target: seqRect
          property: "color"
          from: seqRect.color
          to: "#008080"
          duration: 500
        }
        PropertyAnimation {
          target: seqRect
          property: "color"
          from: seqRect.color
          to: "#F0F8FF"
          duration: 200
        }
      }

      Text {
        id: seqt
        anchors.centerIn: parent
        color: '#B22222'
        font.pointSize: kSeqAnim.running ? 28 : 22
        font.family: 'Courier'
        font.bold: true
        text: kSeqAnim.running ? 'Gemalaya!' : sview.linkSeqInput
      }
    }

    Rectangle {
      id: searchTextRect
      anchors.margins: 8
      Layout.alignment: Qt.AlignLeft
      color: 'cornsilk'
      width: sview.width * 0.3
      height: 32
      visible: sview.actionMode == sview.modes.SEARCH ||
               sview.searchTextInput.length > 0
      border.width: 1
      border.color: 'lightgray'
      radius: 2

      SequentialAnimation {
        id: textFoundAnim

        PropertyAnimation {
          target: searchTextRect
          property: "color"
          from: searchTextRect.color
          to: "#20B2AA"
          duration: 500
        }
        PropertyAnimation {
          target: searchTextRect
          property: "color"
          from: searchTextRect.color
          to: "cornsilk"
          duration: 200
        }
        PropertyAnimation {
          target: searchedText
          property: "color"
          to: "red"
          duration: 200
        }
        PropertyAnimation {
          target: searchedText
          property: "color"
          to: "blue"
          duration: 50
        }
      }

      Text {
        id: searchedText
        anchors.centerIn: parent
        color: 'blue'
        font.pointSize: 16
        font.family: 'Courier'
        font.bold: true
        text: sview.searchTextInput
      }
    }
  }
}
