import QtQuick 2.14
import QtQuick.Controls 2.14

Action {
  property Item stackLayout

  shortcut: Conf.shortcuts.stack.next

  onTriggered: {
    if (stackLayout.currentIndex < (stackLayout.count - 1))
      stackLayout.currentIndex += 1
  }
}
