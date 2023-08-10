import QtQuick 2.14
import QtQuick.Controls 2.14

Action {
  property Item stackLayout
  shortcut: Conf.shortcuts.stack.create

  onTriggered: {
    let obj = stackLayout.spawn()
  }
}

