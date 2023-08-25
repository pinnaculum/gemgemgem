import QtQuick 2.15

AnimatedImage {
  property string imgPath
  source: imgPath ? 'file://' + imgPath : ''
  fillMode: Image.PreserveAspectFit
}
