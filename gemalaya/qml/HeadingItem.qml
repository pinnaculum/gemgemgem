import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.4

Text {
  id: heading
  property string content
  property string hsize: 'h1'

  property Item nextLinkItem
  property Item prevLinkItem

  KeyNavigation.backtab: prevLinkItem
  KeyNavigation.priority: KeyNavigation.BeforeItem
  KeyNavigation.tab: nextLinkItem

  Layout.margins: 5
  Layout.maximumWidth: width
  Layout.alignment: Qt.AlignHCenter

  signal focusRequested()

  TextMetrics {
    id: textmn
    font.underline: true
    font.pointSize: {
      switch(hsize) {
        case 'h1':
          return Conf.fontPrefs.defaultPointSize * 1.5
        case 'h2':
          return Conf.fontPrefs.defaultPointSize * 1.3
        case 'h3':
          return Conf.fontPrefs.defaultPointSize * 1.1
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
  wrapMode: Text.WrapAnywhere
}
