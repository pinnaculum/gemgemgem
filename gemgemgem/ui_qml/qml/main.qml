import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.4
import QtQuick.Window 2.2

import "."

Window {
  id: window
  visible: true

  Rectangle {
    color: '#323232'
    anchors.fill: parent

    ColumnLayout {
      anchors.fill: parent

      RowLayout {
        NavBackButton {
          id: backb
          onClicked: {
            let u = addrc.histPop()

            if (u !== undefined) {
              sview.browse(u, null)
            }
          }
        }
        NavNextButton {
          id: nextb
        }

        GemAddressCtrl {
          id: addrc

          Layout.fillWidth: true
          Layout.minimumHeight: 60
          Layout.maximumHeight: 150

          url: 'gemini://station.martinrue.com'

          onRequested: {
            sview.browse(text, null)
          }
        }

        Text {
          id: currentUrl
        }
        QuitButton {
          width: 150
          height: 100
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
}
