import QtQuick 2.14
import QtQuick.Controls 2.14

Popup {
  id: popup
  closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
  background: Rectangle {
    color: '#708090'
    border.width: 2
    border.color: '#CD853F'
  }
  x: ~~(Overlay.overlay.width / 2 - width / 2)
  y: ~~(Overlay.overlay.height / 2 - height / 2)

  property string version
  property string wheelUrl

  contentItem: ColumnLayout {
    Text {
      text: qsTr(`There is a gemalaya update available (version: ${version})`)
      font.pointSize: 20
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }

    RowLayout {
      spacing: popup.width * 0.10
      Button {
        text: qsTr('Ignore (Escape)')
        padding: 15
        font.pointSize: 16
        onClicked: popup.close()
      }
      Button {
        text: qsTr('Update gemalaya (Ctrl+i)')
        padding: 15
        action: Action {
          shortcut: 'Ctrl+i'
        }
        font.pointSize: 18
        font.bold: true
        background: Rectangle {
          border.width: 2
          border.color: 'darkorange'
          color: 'cornsilk'
        }
        onClicked: {
          gemalaya.installWheelUpdate(wheelUrl)
          popup.close()
        }
      }
    }
  }
}
