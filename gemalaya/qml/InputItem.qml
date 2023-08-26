import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.4

ColumnLayout {
  id: root

  property string sendUrl
  property string promptText

  property ColumnLayout pageLayout

  property string colorDefault: 'cornsilk'
  property string colorHovered: 'white'

  signal sendRequest(url sendUrl, string inputValue)

  function focusInput() {
    input.forceActiveFocus()
  }

  spacing: 30
  Layout.fillWidth: true
  Layout.preferredWidth: width

  Text {
    text: qsTr('Input request: ') + promptText
    color: colorDefault
    font.pointSize: 24
    Layout.fillWidth: true
    horizontalAlignment: Text.AlignHCenter
  }

  TextArea {
    id: input
    wrapMode: TextEdit.WrapAnywhere
    selectByMouse: true
    focus: true
    textMargin: 10

    Layout.margins: 20
    Layout.minimumHeight: root.height * 0.6
    Layout.maximumHeight: root.height * 0.75

    Layout.fillWidth: true
    Layout.fillHeight: true

    Keys.onTabPressed: {
      /* Focus the send button manually when Tab is pressed here */
      if (text.length > 0)
        send.focus = true
    }

    font.pointSize: 22
    font.family: "Segoe UI"

    color: colorDefault
    selectionColor: "steelblue"
    selectedTextColor: "#eee"

    padding: 15

    background: Rectangle {
      color: "#323532"
      border.color: "#4a9ea1"
    }
  }

  ToolButton {
    id: send
    Layout.alignment: Qt.AlignHCenter
    text: qsTr('Send')
    icon.source: Conf.themeRsc('input-send.png')
    icon.width: 32
    icon.height: 32
    font.pointSize: 22
    Keys.onReturnPressed: clicked()

    background: Rectangle {
      implicitWidth: 140
      implicitHeight: 50
      color: parent.focus ? "lightgreen" : "lightsteelblue"
      border.color: parent.focus ? 'black' : '#26282a'
      border.width: parent.focus ? 2 : 1
      radius: 8
    }

    onClicked: {
      if (input.text.length > 0) {
        var urlObject = new URL(
          sendUrl + '?' + encodeURIComponent(input.text))

        sendRequest(urlObject, input.text)
      } else {
        focusInput()
      }
    }
  }

  Text {
    text: qsTr("Hint: once you've finished writing, press the Tab key to focus the send button")
    color: colorDefault
    horizontalAlignment: Text.AlignHCenter
    font.pointSize: 16
    font.italic: true
    Layout.fillWidth: true
  }
}
