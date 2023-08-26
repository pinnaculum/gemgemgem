import QtQuick 2.14
import QtQuick.Controls 2.14

Action {
  property Item stackLayout
  shortcut: Conf.shortcuts.stackCloseSpace

  onTriggered: {
    stackLayout.spaceCloseRequested(stackLayout.currentIndex)

    if (stackLayout.currentIndex != 0) {
      stackLayout.get(stackLayout.currentIndex).close()
    }
  }
}

