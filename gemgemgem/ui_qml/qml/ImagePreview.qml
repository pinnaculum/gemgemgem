import QtQuick 2.15
import QtQuick.Controls 2.4

Image {
  id: popup
  property string imgPath
  source: 'file://' + imgPath
}
