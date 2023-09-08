import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.4

ColumnLayout {
  TabBar {
    Layout.fillWidth: true
    id: bar
    width: parent.width
    currentIndex: 0
    background: Rectangle {
      color: "#eeeeee"
    }

    TabButton {
      text: qsTr("Shortcuts")
      font.pointSize: 18
      background: Rectangle {
        color: parent.checked || parent.pressed ? '#87CEFA' : 'cornsilk'
        border.color: 'black'
        border.width: 1
      }

    }
    TabButton {
      text: qsTr("UI settings")
      font.pointSize: 18
      background: Rectangle {
        color: parent.checked || parent.pressed ? '#FF7F50' : 'cornsilk'
        border.color: 'black'
        border.width: 1
      }
    }
  }

  StackLayout {
    currentIndex: bar.currentIndex
    Layout.fillWidth: true
    Layout.fillHeight: true

    ScrollView {
      id: scroll
      Layout.fillWidth: true
      Layout.fillHeight: true

      ScrollBar.vertical: ScrollBar {
        parent: scroll
        x: scroll.width - width
        height: scroll.height
        width: 20
        policy: ScrollBar.AlwaysOn
      }

      ColumnLayout {
        id: slayout
        Component.onCompleted: {
          for (let [sname, shortcut] of Object.entries(Conf.shortcuts)) {
            var component = Qt.createComponent('./ShortcutConfigItem.qml')
            var item = component.createObject(slayout, {
              name: sname,
              dotName: 'ui.shortcuts.' + sname,
              shortcut: shortcut
            })
          }

          for (let [sname, shortcut] of Object.entries(Conf.stackShortcuts)) {
            var component = Qt.createComponent('./ShortcutConfigItem.qml')
            var item = component.createObject(slayout, {
              name: sname,
              dotName: 'ui.stackShortcuts.' + sname,
              shortcut: shortcut
            })
          }
        }
      }
    }

    ScrollView {
      Layout.fillWidth: true
      Layout.fillHeight: true

      AppConfigSettings {
        anchors.fill: parent
      }
    }
  }

  Text {
    text: qsTr('Press Escape to close')
    font.pointSize: 22
    font.bold: true
    Layout.fillWidth: true
    horizontalAlignment: Text.AlignHCenter
  }
}
