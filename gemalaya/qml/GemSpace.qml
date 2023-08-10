import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.4

import "."

Rectangle {
  id: gemspace

  property StackLayout stackLayout

  color: Conf.gemspace.bgColor

  Component.onCompleted: {
    sched.delay(function(){ addrc.focusInput()}, 100)
  }

  Scheduler {
    id: sched
  }

  Action {
    shortcut: Conf.shortcuts.bookmark
    onTriggered: {
      console.log(addrc.url)
      if (addrc.url) {
        // todo: title
        bookmarksModel.addBookmark(addrc.url, addrc.url)
      }
    }
  }

  ColumnLayout {
    anchors.fill: parent

    RowLayout {
      Text {
        text: gemspace.StackLayout.index
        color: 'red'
        font.pointSize: 26
      }
      NavBackButton {
        id: backb
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
        Layout.maximumHeight: 150

        focus: true
        KeyNavigation.backtab: sview
        KeyNavigation.tab: sview

        onRequested: {
          sview.browse(text, null)
        }
      }

      Text {
        id: currentUrl
      }
      QuitButton {
        onClicked: Qt.quit()
        enabled: true
      }
    }

    GeminiPageView {
      id: sview
      addrController: addrc
    }
  }
}
