import QtQuick 2.14
import QtQuick.Controls 2.14

Action {
  property Item stackLayout
  shortcut: Conf.shortcuts.stack.close

  onTriggered: {
    stackLayout.spaceCloseRequest(stackLayout.currentIndex)
  }
}

