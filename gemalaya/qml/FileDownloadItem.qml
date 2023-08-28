import QtQuick 2.2
import QtQuick.Controls 2.15

ColumnLayout {
  property string message
  property string contentType
  property string filePath
  property string fileUrl

  property alias openButton: openButton

  Text {
    id: control
    Layout.margins: 10
    font.pointSize: 30
    color: '#4169E1'
    text: qsTr('This file was downloaded to: ')
    wrapMode: Text.WrapAnywhere
  }
  Text {
    Layout.margins: 30
    font.pointSize: 18
    color: '#F4A460'
    text: filePath
  }
  Button {
    id: openButton
    text: qsTr('Click or press return to open this file')
    focus: true
    onClicked: gemalaya.fileExec(filePath)
    padding: 40

    Layout.alignment: Text.AlignHCenter
    Keys.onReturnPressed: clicked()

    contentItem: Text {
      text: openButton.text
      Layout.margins: 30
      font.pointSize: 24
      font.bold: true
      opacity: enabled ? 1.0 : 0.3
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
      color: parent.activeFocus ? 'lightsteelblue': 'cornsilk'
      radius: 10
      Behavior on color {
        SequentialAnimation {
          loops: 10
          ColorAnimation { from: "white"; to: "red"; duration: 600 }
          ColorAnimation { from: "red"; to: "white";  duration: 600 }
        }
      }
    }
  }
}
