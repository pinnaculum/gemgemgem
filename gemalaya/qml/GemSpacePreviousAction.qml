import QtQuick 2.14
import QtQuick.Controls 2.14

Action {
  property Item stackLayout

  shortcut: Conf.shortcuts.stackPrevious

  onTriggered: {
    if (stackLayout.currentIndex > 0)
      stackLayout.currentIndex -= 1
    else
      stackLayout.currentIndex = 0
  }
}
