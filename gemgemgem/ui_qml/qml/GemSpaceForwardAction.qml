import QtQuick 2.14
import QtQuick.Controls 2.14

Action {
  property Item stackItem
  shortcut: 'Ctrl+Tab'

  onTriggered: {
    let tidx
    let cindex = stackItem.currentItem.StackView.index

    if (cindex >= 16) {
      tidx = -1
    } else {
      tidx = cindex + 1
    }

    let item = stackItem.get(tidx, StackView.ForceLoad)

    if (item === null) {
      let comp = Qt.createComponent('GemSpace.qml')
      let obj = comp.createObject(stack, {})

      stackItem.push(obj)
    } else {
      stackItem.replace(stackItem.currentItem, item)
    }
  }
}

