import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.4

Text {
  id: heading
  objectName: 'headingItem'

  property string content
  property string hsize: 'h1'

  property Item nextLinkItem
  property Item prevLinkItem

  KeyNavigation.backtab: prevLinkItem
  KeyNavigation.priority: KeyNavigation.BeforeItem
  KeyNavigation.tab: nextLinkItem

  Layout.margins: 5
  Layout.alignment: Qt.AlignHCenter
  Layout.fillWidth: true
  horizontalAlignment: Text.AlignHCenter

  signal focusRequested()

  TextMetrics {
    id: textmn
    font.underline: activeFocus || hsize === 'h1'
    font.pointSize: {
      switch(hsize) {
        case 'h1':
          return activeFocus ?
                 Conf.fontPrefs.defaultPointSize * 1.6 :
                 Conf.fontPrefs.defaultPointSize * 1.5
        case 'h2':
          return activeFocus ?
                 Conf.fontPrefs.defaultPointSize * 1.4 :
                 Conf.fontPrefs.defaultPointSize * 1.3
        case 'h3':
          return activeFocus ?
                 Conf.fontPrefs.defaultPointSize * 1.2 :
                 Conf.fontPrefs.defaultPointSize * 1.1
        default:
          return Conf.fontPrefs.defaultPointSize
      }
    }
    font.bold: true
    text: content
  }

  color: {
    switch(hsize) {
      case 'h1':
        return activeFocus ? Conf.heading.h1.colorFocused : Conf.heading.h1.color
      case 'h2':
        return activeFocus ? Conf.heading.h2.colorFocused : Conf.heading.h2.color
      case 'h3':
        return activeFocus ? Conf.heading.h3.colorFocused : Conf.heading.h3.color
      default:
        return 'white'
    }
  }

  text: textmn.text
  font: textmn.font
  antialiasing: true
  wrapMode: Text.WrapAnywhere
}
