import QtQuick 2.2
import QtQuick.Controls 2.14

ColumnLayout {
  id: itemLayout

  property string title
  property string href
  property string baseUrl

  property alias linkAction: linkAction

  property Item nextLinkItem
  property Item prevLinkItem

  /* The key sequence to access this link */
  property string keybAccessSeq

  property int pointSizeNormal: Conf.links.text.fontSize
  property int pointSizeLarge: Conf.links.text.fontSizeLarge

  signal linkClicked(url baseUrl, string href)
  signal imageClicked(url imgLink)

  Layout.fillWidth: true
  Layout.leftMargin: Conf.links.layout.leftMargin

  KeyNavigation.tab: nextLinkItem
  KeyNavigation.backtab: prevLinkItem
  KeyNavigation.priority: KeyNavigation.BeforeItem
  Keys.onReturnPressed: linkAction.trigger()

  Layout.minimumWidth: parent.width * 0.5
  Layout.maximumWidth: parent.width * 0.8

  onFocusChanged: {
    if (focus) {
      console.log('Focus is on: ' + href)
    }
  }

  Button {
    id: button

    Layout.preferredWidth: parent.width
    Layout.fillWidth: true

    Layout.margins: 5

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onEntered: itemLayout.focus = true
      onExited: itemLayout.focus = false
    }

    SequentialAnimation {
      /*
       * This animation is run when we activate the link
       * (via keyboard sequences or mouse clicks)
       */
      id: linkOpenAnim

      PropertyAnimation {
        target: buttonBg
        property: 'color'
        to: Conf.links.openAnim.buttonBgColor
        duration: 100
      }

      ScaleAnimator {
        target: button
        from: 1
        to: 1.05
        duration: 200
      }

      PropertyAnimation {
        target: shortcutButton
        property: 'border.width'
        from: 1
        to: Conf.links.openAnim.shortcutBorderWidth ? Conf.links.openAnim.shortcutBorderWidth : 2
        duration: 100
      }
      PropertyAnimation {
        target: shortcutButton
        property: 'color'
        to: Conf.links.openAnim.shortcutButtonColor
        duration: 300
      }

      ScriptAction {
        id: clickScript
        script: {
          var urlObject = new URL(gem.buildUrl(href, baseUrl))

          const ext = urlObject.pathname.split(".").pop()
          const imgexts = ['png', 'jpg', 'webm']

          if (imgexts.includes(ext)) {
            var path = gem.downloadToFile(urlObject.toString(), {})

            if (path !== undefined) {
              imgPreview.imgPath = path
              imgPreview.visible = true
            }
          } else {
            linkClicked(urlObject, baseUrl)
          }
        }
      }
    }

    Action {
      id: linkAction
      text: title
      onTriggered: {
        /* Just run the animation, link is activated in the
         * animation's clickScript */
        linkOpenAnim.running = true
      }
    }

    TextMetrics {
      id: textm
      font.family: Conf.links.text.fontFamily
      font.pointSize: pointSizeNormal
      text: title

      /* Elide to the right and set the elide width */
      elideWidth: button.width * 0.7
      elide: Qt.ElideRight
    }

    text: textm.text

    background: Rectangle {
      id: buttonBg
      border.width: parent.hovered ? 2 : 1
      border.color: parent.hovered ? Conf.links.bg.borderColorHovered : Conf.links.bg.borderColor
      radius: 4
      color: button.down ? "#FFDAB9" :
             (itemLayout.focus || parent.hovered ? "#AFEEEE" : "transparent")
    }

    contentItem: RowLayout {
      id: buttonLayout
      spacing: 10

      Rectangle {
        id: shortcutButton
        implicitWidth: keybSeqText.width
        implicitHeight: keybSeqText.height
        border.width: Conf.links.shortcutButton.borderWidth
        border.color: Conf.links.shortcutButton.borderColor
        color: Conf.links.shortcutButton.color
        Text {
          id: keybSeqText
          text: keybAccessSeq
          font.pointSize: Conf.links.shortcutButton.fontSize
          color: Conf.links.shortcutButton.textColor
          anchors.centerIn: parent
          Layout.fillWidth: true
        }
      }

      Text {
        id: te
        text: textm.elidedText
        font: textm.font
        width: textm.width
        height: textm.height
        renderType: Text.NativeRendering
        wrapMode: Text.WrapAnywhere
        elide: Text.ElideRight
        maximumLineCount: 2
        horizontalAlignment: Text.AlignHCenter
        color: button.hovered ? Conf.links.text.colorHovered : Conf.links.text.color
      }
    }

    onClicked: {
      linkAction.trigger()
    }
  }

  ImagePreview {
    id: imgPreview
    visible: false
    Layout.fillWidth: true
  }
}
