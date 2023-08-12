import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.4

Text {
  property string content
  property string hsize: 'h1'

  property Item nextLinkItem
  property Item prevLinkItem

  KeyNavigation.backtab: prevLinkItem
  KeyNavigation.priority: KeyNavigation.BeforeItem
  KeyNavigation.tab: nextLinkItem

  Layout.margins: 10
  Layout.maximumWidth: width
  Layout.alignment: Qt.AlignHCenter
  width: width

  signal focusRequested()

  TextMetrics {
    id: textmn
    font.underline: true
    font.pointSize: {
      switch(hsize) {
        case 'h1':
          return Conf.heading.h1.fontSize
        case 'h2':
          return Conf.heading.h2.fontSize
        case 'h3':
          return Conf.heading.h3.fontSize
        default:
          return 16
      }
    }
    font.bold: true
    text: content
  }

  color: {
    switch(hsize) {
      case 'h1':
        return Conf.heading.h1.color
      case 'h2':
        return Conf.heading.h2.color
      case 'h3':
        return Conf.heading.h3.color
      default:
        return 'white'
    }
  }

  text: textmn.text
  font: textmn.font

  antialiasing: true
  wrapMode: Text.WordWrap
}
