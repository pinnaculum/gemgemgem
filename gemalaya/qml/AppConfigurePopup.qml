import QtQuick 2.14
import QtQuick.Controls 2.14

Popup {
  closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
  background: Rectangle {
    color: '#778899'
    border.width: 1
    border.color: 'black'
  }
  x: ~~(Overlay.overlay.width / 2 - width / 2)
  y: ~~(Overlay.overlay.height / 2 - height / 2)

  contentItem: AppConfigRootItem {
    id: root
    onCloseRequested: close()
  }

  onClosed: Conf.update()
}
