import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.4
import QtQuick.Window 2.2

import "."

Window {
  id: window
  visible: true

  GemSpaceForwardAction {
    stackItem: stack
  }

  Rectangle {
    anchors.fill: parent

    StackView {
      id: stack
      anchors.fill: parent

      initialItem: GemSpace {
        id: space1
      }
    }
  }
}
