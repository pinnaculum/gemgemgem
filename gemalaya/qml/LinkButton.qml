import QtQuick 2.2
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.4

Button {
  id: button

  property string title
  property string href
  property string baseUrl

  /* full URL */
  property url linkUrl

  /* The key sequence to access this link */
  property string keybAccessSeq

  property int pointSizeNormal: Conf.fontPrefs.links.pointSize ? Conf.fontPrefs.links.pointSize : Conf.fontPrefs.defaultPointSize
  property alias linkAction: linkAction

  property Item nextLinkItem
  property Item prevLinkItem

  Layout.fillWidth: true
  Layout.preferredWidth: parent.width * 0.25
  Layout.margins: 2

  KeyNavigation.tab: nextLinkItem
  KeyNavigation.backtab: prevLinkItem
  KeyNavigation.priority: KeyNavigation.BeforeItem

  Keys.onReturnPressed: linkAction.trigger()
  Keys.onEnterPressed: linkAction.trigger()
  Keys.onSpacePressed: linkAction.trigger()

  signal linkClicked(string baseUrl, string href)

  onFocusChanged: {
    /* Notify the link grid */
    button.parent.linkFocused(focus)
  }

  Action {
    /* Action to unfocus from this link and the grid it's bound to,
     * and tell the grid to focus whatever is next in the layout */

    enabled: button.activeFocus
    shortcut: Conf.linksShortcuts.skipLinksGrid
    onTriggered: button.parent.skipGrid()
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: linkAction.trigger()
  }

  Action {
    id: linkAction
    text: title
    onTriggered: {
      linkClicked(linkUrl, baseUrl)
    }
  }

  background: Rectangle {
    id: buttonBg
    border.width: parent.hovered ? Conf.links.bg.borderWidthHovered : Conf.links.bg.borderWidth
    border.color: parent.hovered ? Conf.links.bg.borderColorHovered : Conf.links.bg.borderColor
    radius: 4
    color: button.focus || parent.hovered ? Conf.links.bg.colorActive : "transparent"
  }

  contentItem: RowLayout {
    id: buttonLayout
    spacing: 5

    Rectangle {
      id: shortcutButton
      implicitWidth: keybSeqText.width + 8
      implicitHeight: keybSeqText.height + 8
      border.width: Conf.links.shortcutButton.borderWidth
      border.color: Conf.links.shortcutButton.borderColor
      radius: Conf.links.shortcutButton.radius
      color: button.focus ? Conf.links.shortcutButton.colorFocused : Conf.links.shortcutButton.color

      Text {
        id: keybSeqText
        text: keybAccessSeq
        font.pointSize: Conf.fontPrefs.links.shortcutFontSize
        font.bold: true
        font.family: 'Courier'
        color: Conf.links.shortcutButton.textColor
        anchors.centerIn: parent
        Layout.fillWidth: true
      }
    }

    Text {
      id: te
      text: title
      font.family: Conf.links.text.fontFamily
      font.pointSize: activeFocus ? pointSizeNormal * 1.5 : pointSizeNormal
      renderType: Text.NativeRendering
      wrapMode: Text.WrapAnywhere
      elide: Text.ElideRight
      maximumLineCount: 4
      horizontalAlignment: Text.AlignLeft
      color: button.focus || button.hovered ? Conf.links.text.colorHovered : Conf.links.text.color
      Layout.fillWidth: true
      Layout.leftMargin: 5
    }
  }

  onClicked: {
    linkAction.trigger()
  }
}
