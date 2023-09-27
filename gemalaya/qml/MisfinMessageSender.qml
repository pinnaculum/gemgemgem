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

  x: ~~(Overlay.overlay.width * 0.15)
  y: ~~(Overlay.overlay.height / 2 - height / 2)
  width: ~~((2 * Overlay.overlay.width) / 3)
  height: ~~(Overlay.overlay.height / 2)

  property string recipientAddr
  property alias message: message

  Misfin {
    id: client
    onSent: {
      popup.close()
      popup.destroy()
      sendSuccess.open()
    }
    onSendError: {
      sendError.informativeText = errorMessage
      sendError.open()
    }
  }
  MessageDialog {
    id: sendError
    text: qsTr("Send error")
    buttons: MessageDialog.Ok
  }
  MessageDialog {
    id: sendSuccess
    text: qsTr("The message was sent successfully!")
    buttons: MessageDialog.Ok
  }

  function validMisfinAddr(addr) {
    /* TODO: use a more restrictive regex */
    return addr.match(/^[\w]+@\S+$/)
  }

  contentItem: ColumnLayout {
    id: root

    RowLayout {
      Text {
        Layout.maximumWidth: parent.width * 0.4
        text: qsTr('Misfin: send to')
        font.pointSize: 16
        font.bold: true
        color: '#8B4513'
      }
      TextField {
        id: recipient
        text: recipientAddr
        Layout.fillWidth: true
        font.pointSize: 16
        maximumLength: 128
        placeholderText: 'mailbox@domain.com'
      }
    }

    Flickable {
      clip: true
      contentWidth: message.paintedWidth
      contentHeight: message.paintedHeight
      Layout.fillWidth: true
      Layout.fillHeight: true

      ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AlwaysOn
        width: 15
      }

      TextArea.flickable: TextArea {
        id: message
        focus: true
        font.pointSize: 18
        font.family: 'DejaVu sans'
        wrapMode: TextEdit.WordWrap
      }
    }

    RowLayout {
      Button {
        text: 'Cancel'
        font.pointSize: 16
        Layout.fillWidth: true
        onClicked: {
          popup.close()
        }
      }

      Button {
        id: send
        text: 'Send (Ctrl+s)'
        font.pointSize: 20
        Layout.fillWidth: true
        action: Action {
          shortcut: 'Ctrl+s'
        }
        onClicked: {
          if (recipient.text.length === 0 || !validMisfinAddr(recipient.text)) {
            recipient.forceActiveFocus()
            return
          }

          client.send(
            client.defaultIdentityPath(),
            recipient.text,
            message.text
          )
        }
      }
    }
  }
}
