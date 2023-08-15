import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.4

StackLayout {
  id: stackl
  Layout.fillWidth: true
  Layout.fillHeight: true

  property alias gspace0: gspace0

  signal openInSwitch()
  signal spaceChanged(int index)
  signal spaceCloseRequested(int index)

  onCurrentIndexChanged: {
    spaceChanged(currentIndex)
  }

  function get(idx) {
    /* Get the item in the stack with this index */
    if (idx <= children.length - 1)
      return children[idx]
  }

  function closeAll() {
    for (let i=1; i < children.length; i++) {
      children[i].close()
    }
  }

  function spawn(linkUrl) {
    let comp = Qt.createComponent('GemSpace.qml')
    let obj = comp.createObject(stackl, {
      stackLayout: stackl,
      startUrl: linkUrl
    })

    currentIndex = count - 1
    return obj
  }

  GemSpace {
    id: gspace0
    stackLayout: stackl
  }
}
