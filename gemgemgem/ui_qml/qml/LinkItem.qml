import QtQuick 2.2
import QtQuick.Controls 2.14

Button {
  id: button

  property string title
  property string href
  property string baseUrl

  /* The key sequence to access the link */
  property string keybAccessSeq

  property int pointSizeNormal: 16
  property int pointSizeLarge: 24

  signal linkClicked(string baseUrl, string href)
  signal imageClicked(url imgLink)

  Layout.margins: 15

  Action {
    id: linkAction
    text: title
    shortcut: keybAccessSeq
    onTriggered: {
      var urlObject = new URL(gem.buildUrl(href, baseUrl))

      const ext = urlObject.pathname.split(".").pop()
      const imgexts = ['png', 'jpg', 'webm']

      if (imgexts.includes(ext)) {
        var path = gem.downloadToFile(urlObject.toString(), {})

        if (path !== undefined) {
          var component = Qt.createComponent('ImagePreview.qml')
          var item = component.createObject(coll, {
            imgPath: path
          })
        }
      } else {
        linkClicked(urlObject, baseUrl)
      }
    }
  }

  TextMetrics {
    id: textm
    font.family: "DejaVuSans"
    font.pointSize: pointSizeNormal
    text: title
  }

  text: textm.text

  background: Rectangle {
    border.width: parent.hovered ? 2 : 1
    border.color: parent.hovered ? 'black' : 'darkgray'
    color: parent.down ? "#bbbbbb" :
           (parent.hovered ? "#008B8B" : "#FFE4C4")
  }

  contentItem: ColumnLayout {
    id: coll
    RowLayout {
      spacing: 10
      Rectangle {
        implicitWidth: t.width * 1.2
        implicitHeight: t.height * 1.2
        border.width: 1
        border.color: 'red'
        color: 'lightsteelblue'
        Text {
          id: t
          text: keybAccessSeq
          font.pointSize: 28
          color: '#A52A2A'
          anchors.centerIn: parent
        }
      }

      Text {
        id: te
        text: button.text
        font: textm.font
        width: textm.width < parent.width ? textm.width * 1.2 : parent.width * 0.9
        height: textm.height * 1.2
        renderType: Text.NativeRendering
        wrapMode: Text.WrapAnywhere
        elide: Text.ElideRight
        maximumLineCount: 3
        horizontalAlignment: Text.AlignHCenter
      }
    }
  }

  onClicked: {
    linkAction.trigger(this)
  }
}
