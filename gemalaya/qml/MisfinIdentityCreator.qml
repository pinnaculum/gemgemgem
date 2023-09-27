import QtQuick 2.14
import QtQuick.Controls 2.14

Popup {
  id: popup
  closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
  background: Rectangle {
    color: '#778899'
    border.width: 1
    border.color: 'black'
  }
  x: ~~(Overlay.overlay.width / 2 - width / 2)
  y: ~~(Overlay.overlay.height / 2 - height / 2)
  width: ~~(Overlay.overlay.width / 2)
  height: ~~(Overlay.overlay.height / 2)

  property string recipientAddr

  MessageDialog {
    id: createdMessage
    text: qsTr("Identity created")
    informativeText: qsTr("You can now send messages to misfin addresses")
    buttons: MessageDialog.Ok
  }

  contentItem: ColumnLayout {
    id: root

    Misfin {
      id: client
    }

    /*
    RowLayout {
      Text {
        text: 'Identity name'
      }
      TextField {
        id: iname
        Layout.fillWidth: true
        text: 'test'
      }
    }
    */
    RowLayout {
      Text {
        text: qsTr('Create a misfin identity')
        font.pointSize: 20
        font.bold: true
      }
    }

    RowLayout {
      Text {
        text: qsTr('Misfin mail address')
        font.pointSize: 16
        font.bold: true
      }
      TextField {
        id: addr
        Layout.fillWidth: true
        font.pointSize: 16
        maximumLength: 128
        placeholderText: 'mailbox@domain.com'
      }
    }
    RowLayout {
      Text {
        text: qsTr('Fullname')
        font.pointSize: 16
      }
      TextField {
        id: blurb
        Layout.fillWidth: true
        font.pointSize: 16
        maximumLength: 64
        placeholderText: 'Tyler Durden'
      }
    }

    RowLayout {
      Button {
        text: 'Cancel'
        font.pointSize: 14
        Layout.fillWidth: true
        onClicked: {
          popup.close()
          popup.destroy()
        }
      }

      Button {
        text: 'Create'
        Layout.fillWidth: true
        font.pointSize: 14
        onClicked: {
          let [mailbox, hostname] = addr.text.split('@')

          if (mailbox.length === 0 || hostname.length === 0) {
            addr.forceActiveFocus()
            return
          }

          let result = client.makeCert(mailbox, blurb.text, hostname,
            client.defaultIdentityPath()
          )

          if (result === true) {
            popup.close()
            popup.destroy()
            createdMessage.open()
          }
        }
      }
    }
  }
}
