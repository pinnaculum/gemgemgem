import QtQuick 2.2
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.4

ColumnLayout {
  id: itemLayout

  property string title
  property string href
  property string baseUrl

  /* full URL */
  property url linkUrl

  property bool autoPreview: false

  property alias linkAction: linkAction

  property ColumnLayout pageLayout

  property Item nextLinkItem
  property Item prevLinkItem

  /* The key sequence to access this link */
  property string keybAccessSeq

  property int pointSizeNormal: Conf.fontPrefs.links.pointSize ? Conf.fontPrefs.links.pointSize : Conf.fontPrefs.defaultPointSize

  signal linkClicked(string baseUrl, string href)
  signal imageClicked(url imgLink)

  Layout.leftMargin: Conf.links.layout.leftMargin

  KeyNavigation.tab: nextLinkItem
  KeyNavigation.backtab: prevLinkItem
  KeyNavigation.priority: KeyNavigation.BeforeItem

  /* The Return, Enter or Space keys will open the link */
  Keys.onReturnPressed: linkAction.trigger()
  Keys.onEnterPressed: linkAction.trigger()
  Keys.onSpacePressed: linkAction.trigger()

  onFocusChanged: {
    if (focus) {
      console.log('Focus is on: ' + href)

      pageLayout.delayScrollTo(itemLayout.y)
    }
  }

  function setup() {
    var objUrl = new URL(linkUrl)
    var mtype = gemalaya.mimeTypeGuess(objUrl.pathname)

    var mcfg = Conf.cfgForMimeType(mtype)

    if (mcfg != null) {
      /* See if we want to automatically preview this object */
      if (mcfg.hasOwnProperty('autoPreview') && mcfg.autoPreview == true) {
        autoPreview = true
        linkAction.trigger()
      }
    }
  }

  GeminiAgent {
    id: agent
    onFileDownloaded: {
      console.log(`${resp.url}: meta is ${resp.meta}`)

      if (resp.meta.startsWith('video') || resp.meta.startsWith('audio')) {
        var component = Qt.createComponent('MPlayer.qml')

        if (component.status == Component.Ready) {
          var item = component.createObject(itemLayout, {
            width: itemLayout.width,
            height: 420,
            source: resp.path
          })
        }
      } else if (resp.meta.startsWith('image')) {
        imgPreview.imgPath = resp.path
        imgPreview.visible = true
      }
    }
  }

  Button {
    id: button

    Layout.fillWidth: true
    Layout.margins: 2

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onClicked: linkAction.trigger()
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
        id: openScript
        script: {
          var urlObject = new URL(linkUrl)

          var mtype = gemalaya.mimeTypeGuess(urlObject.pathname)
          var [mcat, mclass] = mtype.split('/')
          var mediacats = ['image', 'audio', 'video']

          if (urlObject.protocol == 'gemini:' &&
              (mediacats.includes(mcat) || autoPreview)) {
            agent.downloadToFile(urlObject.toString(), {})
          } else {
            linkClicked(urlObject.toString(), baseUrl)
          }
        }
      }
    }

    Action {
      id: linkAction
      text: title
      onTriggered: {
        /* Just run the animation, link is activated in the
         * animation's openScript */
        linkOpenAnim.running = true
      }
    }

    TextMetrics {
      id: textm
      font.family: Conf.links.text.fontFamily
      font.pointSize: activeFocus ? pointSizeNormal * 1.5 : pointSizeNormal
      text: title

      /* Elide to the right and set the elide width */
      elideWidth: itemLayout.width * 0.9
      elide: Qt.ElideRight
    }

    text: textm.text

    background: Rectangle {
      id: buttonBg
      border.width: parent.hovered ? Conf.links.bg.borderWidthHovered : Conf.links.bg.borderWidth
      border.color: parent.hovered ? Conf.links.bg.borderColorHovered : Conf.links.bg.borderColor
      radius: 4
      color: itemLayout.focus || parent.hovered ? Conf.links.bg.colorActive : "transparent"
    }

    contentItem: RowLayout {
      id: buttonLayout
      spacing: 5

      Rectangle {
        id: shortcutButton
        implicitWidth: keybSeqText.width + 8
        implicitHeight: keybSeqText.height + 4
        border.width: Conf.links.shortcutButton.borderWidth
        border.color: Conf.links.shortcutButton.borderColor
        radius: Conf.links.shortcutButton.radius
        color: itemLayout.focus ? Conf.links.shortcutButton.colorFocused : Conf.links.shortcutButton.color

        Text {
          id: keybSeqText
          text: keybAccessSeq
          font.pointSize: Conf.fontPrefs.links.shortcutFontSize
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
        horizontalAlignment: Text.AlignLeft
        color: itemLayout.focus || button.hovered ? Conf.links.text.colorHovered : Conf.links.text.color
        Layout.fillWidth: true
        Layout.leftMargin: 15
      }

      AnimatedImage {
        id: loadingClip
        property bool isActive: linkOpenAnim.running || agent.dlqsize > 0
        visible: isActive
        playing: isActive
        source: Conf.themeRsc('loading.gif')
        fillMode: Image.PreserveAspectFit
        Layout.maximumWidth: 32
        Layout.maximumHeight: 32
      }
    }

    onClicked: {
      linkAction.trigger()
    }
  }

  ImagePreview {
    id: imgPreview
    visible: false
    Layout.maximumWidth: pageLayout.width * 0.75
  }
}
