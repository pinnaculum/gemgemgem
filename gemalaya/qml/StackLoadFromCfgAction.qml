import QtQuick 2.14
import QtQuick.Controls 2.14

Action {
  property Item stackLayout
  property int index

  onTriggered: {
    var urls = Conf.get('savedStacks.stack' + index)
    var idx = 0
    var gemspace

    if (!urls) {
      return
    }

    console.log(urls)

    for (var storedUrl of urls) {
      if ((stackLayout.children.length - 1) < idx) {
        gemspace = stackLayout.spawn(null, true)
      } else {
        gemspace = stackLayout.children[idx]
      }

      gemspace.addrc.requested(storedUrl)

      idx += 1
    }
  }
}
