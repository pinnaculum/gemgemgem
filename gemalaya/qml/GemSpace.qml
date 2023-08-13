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

  color: Conf.gemspace.bgColor

  function chSpaceSwitch() {
    if (StackLayout.isCurrentItem) {
      switch(openIn) {
        case 0:
          openIn = 1
          break
        case 1:
          openIn = 0
          break
        case 2:
          openIn = 0
          break
      }
    }
  }

  function onSpaceChanged(index) {
    if (StackLayout.index == stackLayout.currentIndex) {
      if (sview.page.empty)
        addrc.focusInput()
      else
        sview.page.forceActiveFocus()
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

  Component.onCompleted: {
    stackLayout.openInSwitch.connect(chSpaceSwitch)
    stackLayout.spaceChanged.connect(onSpaceChanged)
    stackLayout.spaceCloseRequest.connect(onSpaceClose)

    if (startUrl.toString().length > 0) {
      /* In new space */
      sview.browse(startUrl, null)
    } else {
      /* Focus the address bar */
      sched.delay(function(){ addrc.focusInput()}, 100)
    }
  }

  Scheduler {
    id: sched
  }

  Action {
    shortcut: Conf.shortcuts.bookmark
    enabled: gemspace.visible
    onTriggered: {
      if (addrc.url) {
        // todo: set title
        bookmarksModel.addBookmark(addrc.url, addrc.url)
        addrc.animate()
      }
    }
  }

  ColumnLayout {
    anchors.fill: parent

    RowLayout {
      Text {
        text: gemspace.StackLayout.index
        color: 'red'
        font.pointSize: 24
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

        Layout.fillWidth: true
        Layout.minimumHeight: 60
        Layout.maximumHeight: 120

        KeyNavigation.backtab: sview
        KeyNavigation.tab: sview

        onHistorySizeChanged: {
          backb.enabled = hsize > 1
        }

        onRequested: {
          sview.browse(text, null)
        }
      }

      Text {
        id: currentUrl
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
            return 'blue'
          }
          if (openIn == 1) {
            return 'red'
          }
          if (openIn == 2) {
            return 'green'
          }
        }

        Text {
          text: openIn == 0 ? 'S' : 'N'
          anchors.centerIn: parent
          font.pointSize: 18
          color: openType.ocolor
        }
      }

      QuitButton {
        onClicked: Qt.quit()
        enabled: true
      }
    }

    GeminiPageView {
      id: sview
      addrController: addrc

      onLinkActivated: {
        if (openIn === 0) {
          sview.browse(linkUrl.toString(), baseUrl)
        } else if (openIn === 1) {
          let space = stackLayout.spawn(linkUrl)
        }
      }
    }

    Rectangle {
      id: seqRect
      anchors.margins: 8
      Layout.alignment: Qt.AlignRight
      color: 'transparent'
      width: sview.width * 0.2
      height: 32
      visible: sview.linkSeqInput.length > 0
      border.width: 1
      border.color: 'lightgray'
      radius: 2

      Text {
        id: seqt
        anchors.centerIn: parent
        color: 'darkorange'
        font.pointSize: 22
        font.family: 'Courier'
        text: sview.linkSeqInput
      }
    }
  }
}
