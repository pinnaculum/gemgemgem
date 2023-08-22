import QtQuick 2.15

Image {
  property string imgPath
  source: imgPath ? 'file://' + imgPath : ''
  fillMode: Image.PreserveAspectFit
}
