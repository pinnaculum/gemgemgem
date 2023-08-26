import QtQuick 2.14
import QtQuick.Controls 2.14

Action {
  property Item stackLayout

  shortcut: Conf.shortcuts.stackCycle

  onTriggered: {
    if (stackLayout.currentIndex < (stackLayout.count - 1))
      stackLayout.currentIndex += 1
    else
      stackLayout.currentIndex = 0
  }
}
