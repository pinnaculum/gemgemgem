import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.4

ColumnLayout {
  signal closeRequested()

  TabBar {
    Layout.fillWidth: true
    id: bar
    width: parent.width
    currentIndex: 0
    background: Rectangle {
      color: "#eeeeee"
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

    TabButton {
      text: qsTr("Shortcuts")
      font.pointSize: 18
      background: Rectangle {
        color: parent.checked || parent.pressed ? '#87CEFA' : 'cornsilk'
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
      Layout.fillWidth: true
      Layout.fillHeight: true

      ScrollBar.vertical.policy: ScrollBar.AlwaysOn
      ScrollBar.vertical.width: 20

      AppConfigSettings {
        anchors.fill: parent
        onCloseSettings: closeRequested()
      }
    }

    ScrollView {
      id: scroll
      Layout.fillWidth: true
      Layout.fillHeight: true

      ScrollBar.vertical.policy: ScrollBar.AlwaysOn
      ScrollBar.vertical.width: 20

      function listShortcuts(parent, shortcuts, dotPrefix) {
        for (let [sname, shortcut] of Object.entries(shortcuts)) {
          Qt.createComponent('./ShortcutConfigItem.qml').createObject(
            parent, {
              name: sname,
              dotName: dotPrefix + '.' + sname,
              shortcut: shortcut
          })
        }
      }

      ColumnLayout {
        Layout.fillHeight: true
        Layout.fillWidth: true

        Text {
          text: qsTr('Main shortcuts')
          font.pointSize: 20
          font.bold: true
        }

        ColumnLayout {
          Component.onCompleted: scroll.listShortcuts(this, Conf.shortcuts, 'ui.shortcuts')
        }

        Text {
          text: qsTr('Stack shortcuts')
          font.pointSize: 20
          font.bold: true
        }

        ColumnLayout {
          Component.onCompleted: scroll.listShortcuts(this, Conf.stackShortcuts, 'ui.stackShortcuts')
        }

        Text {
          text: qsTr('Links shortcuts')
          font.pointSize: 20
          font.bold: true
        }

        ColumnLayout {
          Component.onCompleted: scroll.listShortcuts(this, Conf.linksShortcuts, 'ui.linksShortcuts')
        }

        Text {
          text: qsTr('Text items shortcuts')
          font.pointSize: 20
          font.bold: true
        }

        ColumnLayout {
          Component.onCompleted: scroll.listShortcuts(this, Conf.textItemShortcuts, 'ui.textItemShortcuts')
        }
      }
    }
  }

  RowLayout {
    Text {
      text: qsTr('Press Escape to close this dialog')
      font.pointSize: 18
      font.bold: true
      Layout.fillWidth: true
      horizontalAlignment: Text.AlignHCenter
    }
    Button {
      text: qsTr('Close')
      onClicked: closeRequested()
      font.pointSize: 14
      font.bold: true
    }
  }
}
