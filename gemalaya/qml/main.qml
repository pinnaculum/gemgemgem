import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.4
import QtQuick.Window 2.2

import "."

Window {
  id: window
  visible: true

  GemSpaceCreateAction {
    stackLayout: stackl
  }
  GemSpaceCycleAction {
    stackLayout: stackl
  }

  ColumnLayout {
    anchors.fill: parent

    StackLayout {
      id: stackl
      Layout.fillWidth: true
      Layout.fillHeight: true

      function spawn() {
        let comp = Qt.createComponent('GemSpace.qml')
        let obj = comp.createObject(stackl, {stackLayout: stackl})

        currentIndex = count - 1
        return obj
      }

      GemSpace {
        id: gspace0
      }
    }
  }
}
