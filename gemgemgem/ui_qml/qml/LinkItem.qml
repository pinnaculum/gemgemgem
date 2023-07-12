import QtQuick 2.2
import QtQuick.Controls 2.14

ColumnLayout {
  id: itemLayout

  property string title
  property string href
  property string baseUrl

  /* The key sequence to access this link */
  property string keybAccessSeq

  property int pointSizeNormal: 16
  property int pointSizeLarge: 24

  signal linkClicked(url baseUrl, string href)
  signal imageClicked(url imgLink)

  Layout.maximumWidth: parent.width
  Layout.fillWidth: true
  Layout.leftMargin: 15

  Button {
    id: button

    Layout.maximumWidth: parent.width * 0.6
    Layout.minimumWidth: parent.width * 0.3
    Layout.fillWidth: true

    Layout.margins: 5

    SequentialAnimation {
      /*
       * This animation is run when we activate the link
       * (via keyboard sequences or mouse clicks)
       */
      id: linkOpenAnim

      PropertyAnimation {
        target: itemLayout
        property: 'Layout.leftMargin'
        to: 90
        duration: 300
      }
      PropertyAnimation {
        target: buttonBg
        property: 'color'
        to: '#FAF0E6'
        duration: 200
      }

      ScaleAnimator {
        target: button
        from: 1
        to: 1.2
        duration: 300
      }

      PropertyAnimation {
        target: buttonRect
        property: 'border.width'
        from: 1
        to: 2
        duration: 100
      }
      PropertyAnimation {
        target: buttonRect
        property: 'color'
        to: '#9ACD32'
        duration: 700
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
      shortcut: keybAccessSeq
      onTriggered: {
        /* Just run the animation, link is activated in the
         * animation's clickScript */
        linkOpenAnim.running = true
      }
    }

    function relatedChildren() {
      var component = Qt.createComponent('ImagePreview.qml')
      button.ImagePreviewItem = component.createObject(buttonLayout, {
        imgPath: 'test.png'
      })

      return [button.ImagePreviewItem]
    }

    TextMetrics {
      id: textm
      font.family: "DejaVuSans"
      font.pointSize: pointSizeNormal
      text: title

      /* Elide to the right and set the elide width */
      elideWidth: parent.width * 0.5
      elide: Qt.ElideRight
    }

    text: textm.text

    background: Rectangle {
      id: buttonBg
      border.width: parent.hovered ? 2 : 1
      border.color: parent.hovered ? '#DEB887' : 'darkgray'
      radius: 4
      color: button.down ? "#FFDAB9" :
             (parent.hovered ? "#AFEEEE" : "transparent")
    }

    contentItem: RowLayout {
      id: buttonLayout
      spacing: 10
      Rectangle {
        id: buttonRect
        implicitWidth: keybSeqText.width * 1.1
        implicitHeight: keybSeqText.height * 1.1
        border.width: 1
        border.color: 'darkorange'
        color: 'lightsteelblue'
        Text {
          id: keybSeqText
          text: keybAccessSeq
          font.pointSize: 22
          color: '#A52A2A'
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
        color: button.hovered ? '#1e90ff' : '#00bfff'
      }
    }

    onClicked: {
      linkAction.trigger(this)
    }
  }

  ImagePreview {
    id: imgPreview
    visible: false
    Layout.fillWidth: true
  }
}
