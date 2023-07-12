import QtQuick 2.15

Image {
  id: popup
  property string imgPath
  source: imgPath ? 'file://' + imgPath : ''
  fillMode: Image.PreserveAspectFit
}
