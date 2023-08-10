import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.4

Rectangle {
  property string sendUrl
  property string promptText

  property string colorDefault: 'cornsilk'
  property string colorHovered: 'white'

  signal sendRequest(url sendUrl, string inputValue)

  ColumnLayout {
    anchors.fill: parent
    id: control
    spacing: 30

    Text {
      text: qsTr('Input request: ') + promptText
      color: colorDefault
      font.pointSize: 26
      Layout.alignment: Qt.AlignHCenter
    }

    TextArea {
      id: input
      wrapMode: TextEdit.WordWrap
      selectByMouse: true
      focus: true

      Layout.margins: 10
      Layout.minimumWidth: 320
      Layout.minimumHeight: 240
      Layout.fillWidth: true
      Layout.fillHeight: true

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
      Layout.alignment: Qt.AlignHCenter
      text: qsTr('Send')
      icon.source: Conf.themeRsc('input-send.png')
      icon.width: 32
      icon.height: 32
      background: Rectangle {
        implicitWidth: 140
        implicitHeight: 50
        color: parent.checked ? "darkorange" :
               (parent.hovered ? "#4a9ea1" : "lightsteelblue")
        border.color: parent.hovered ? 'black' : '#26282a'
        border.width: 2
        radius: 8
      }

      onClicked: {
        var urlObject = new URL(
          sendUrl + '?' + encodeURIComponent(input.text))

        sendRequest(urlObject, input.text)
      }
    }
  }
}
