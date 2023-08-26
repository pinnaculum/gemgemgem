import QtQuick 2.14
import QtQuick.Controls 2.14

Action {
  property Item stackLayout
  shortcut: Conf.shortcuts.stackCreateSpace

  onTriggered: {
    let obj = stackLayout.spawn(null)
  }
}

