import QtQuick 2.2
import QtQuick.Controls 2.15

Text {
  id: control

  property string message
  property Item nextLinkItem
  property Item prevLinkItem

  Layout.margins: 10

  color: '#FFD700'
  text: message
  font.pointSize: 24
  font.family: 'Courier'
  wrapMode: Text.WordWrap
}
