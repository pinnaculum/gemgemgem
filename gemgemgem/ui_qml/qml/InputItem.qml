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

    Text {
      text: promptText
      color: colorDefault
      font.pointSize: 26
    }

    TextEdit {
      id: input
      property bool hovered



      Layout.margins: 10
      Layout.minimumWidth: 320
      Layout.minimumHeight: 240
      Layout.fillWidth: true
      Layout.fillHeight: true
      selectByMouse: true
      height: 320

      readOnly: false
      color: colorDefault
      font.pointSize: 22
    }

    Button {
      text: qsTr('Send')
      onClicked: {
        var urlObject = new URL(
          sendUrl + '?' + encodeURIComponent(input.text))

        sendRequest(urlObject, input.text)
      }
    }
  }
}
