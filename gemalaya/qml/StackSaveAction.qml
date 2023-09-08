import QtQuick 2.14
import QtQuick.Controls 2.14

Action {
  property Item stackLayout
  property int index

  onTriggered: {
    var urls = []

    for (var idx=0; idx < stackLayout.children.length; idx++) {
      let gemspace = stackLayout.children[idx]

      if (gemspace.currentUrl.length > 0) {
        urls.push(gemspace.currentUrl)
      }
    }

    Conf.set('savedStacks.stack' + index, urls)
    Conf.update()
  }
}
