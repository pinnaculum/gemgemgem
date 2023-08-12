import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.4

StackLayout {
  id: stackl
  Layout.fillWidth: true
  Layout.fillHeight: true

  signal openInSwitch()
  signal spaceChanged(int index)
  signal spaceCloseRequest(int index)

  onCurrentIndexChanged: {
    spaceChanged(currentIndex)
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
