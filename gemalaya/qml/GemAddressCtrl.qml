import QtQuick 2.2
import QtQuick.Controls 2.4
import Qt.labs.qmlmodels 1.0

import "."

Item {
  id: control
  property int editDelay: Conf.ui.urlCompletionTimeout
  property bool hovered: false

  property alias url: urlField.text
  property alias input: urlField

  property var history: []
  property int hlength: {
    return history.length
  }

  signal edited(string text)
  signal requested(string text)
  signal hidden()
  signal unfocusRequest()
  signal historySizeChanged(int hsize)

  function histAdd(url) {
    if (!history.includes(url)) {
      history.push(url)
      historySizeChanged(history.length)
    }
  }
  function histPop() {
    if (history.length > 1) {
      history.pop()
      historySizeChanged(history.length)
      return history[history.length - 1]
    }
  }

  function focusInput() {
    input.forceActiveFocus()
  }

  function unfocus() {
    focus = false
  }

  function animate() {
    bmAnim.running = true
  }

  Scheduler {
    id: sched
  }

  implicitHeight: urlField.height
  Layout.minimumHeight: urlField.contentHeight + 32

  Keys.onEscapePressed: {
    hovered = false
    sched.cancel()
    unfocusRequest()
  }

  Keys.onDownPressed: {
    /* Show all bookmarks when Down is pressed if the field is empty */
    if (urlField.text.length == 0)
      lookupBookmarks(null)
  }

  SequentialAnimation {
    /* Simple animation for when we bookmark the url */
    id: bmAnim

    PropertyAnimation {
      target: bgr
      property: 'border.width'
      from: 1
      to: 2
      duration: 100
    }
    PropertyAnimation {
      target: bgr
      property: 'border.color'
      to: 'darkorange'
      duration: 100
    }
    PropertyAnimation {
      target: bgr
      property: 'radius'
      to: 10
      duration: 100
    }

    PauseAnimation {
      duration: 300
    }

    PropertyAnimation {
      target: bgr
      property: 'border.width'
      from: 2
      to: 1
      duration: 100
    }
    PropertyAnimation {
      target: bgr
      property: 'border.color'
      to: 'lightsteelblue'
      duration: 100
    }
    PropertyAnimation {
      target: bgr
      property: 'radius'
      to: 0
      duration: 100
    }
  }

  Action {
    id: focusAction
    shortcut: Conf.shortcuts.urlEdit
    enabled: control.visible
    onTriggered: {
      urlField.forceActiveFocus()
      urlField.selectAll()
      sched.cancel()
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onEntered: {
      hovered = true
      sched.cancel()
    }
    onExited: hovered = false
    onClicked: urlField.forceActiveFocus()
  }

  Rectangle {
    id: bgr
    anchors.fill: parent
    color: urlField.focus ? Conf.theme.url.bg.colorFocused : Conf.theme.url.bg.color
    border.width: Conf.theme.url.bg.borderWidth
    border.color: Conf.theme.url.bg.borderColor
    radius: Conf.theme.url.bg.radius
  }

  ListModel {
    id: bookmarksm
  }

  Popup {
    id: bmpopup
    width: control.width
    height: Conf.theme.urlCompletionPopup.height ? Conf.theme.urlCompletionPopup.height : 280
    x: urlField.x
    y: urlField.y + urlField.height
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
    background: Rectangle {
      color: Conf.theme.urlCompletionPopup.bg.color
      border.width: 1
      border.color: Conf.theme.urlCompletionPopup.bg.borderColor
    }

    contentItem: TableView {
      id: tableview
      focus: true
      clip: true
      model: bookmarksModel

      ScrollBar.vertical: ScrollBar {
        parent: tableview
        width: 20
        policy: ScrollBar.AlwaysOn
      }

      Keys.onReturnPressed: {
        var data = bookmarksModel.getFromRow(tableview.currentRow)

        if (data !== undefined) {
          let bmurl = data[0]
          control.requested(bmurl)
          bmpopup.close()
          sched.cancel()
        }
      }

      signal clicked(string itemUrl)

      TableModelColumn { display: "title" }
      TableModelColumn { display: "url" }

      selectionModel: ItemSelectionModel {}
      keyNavigationEnabled: true

      SelectionRectangle {
        target: tableview
      }

      delegate: Rectangle {
        id: del
        required property bool selected
        required property bool current
        implicitWidth: column == 0 ? control.width * 0.7 : control.width * 0.2
        implicitHeight: textm.height + 8
        color: current ? Conf.theme.urlCompletionPopup.delegate.colorSelected : 'transparent'

        TextMetrics {
          id: textm
          font.family: 'Courier'
          font.pointSize: Conf.theme.urlCompletionPopup.delegate.fontSize
          font.bold: column == 0
          text: display
          elideWidth: del.width * 0.9
          elide: Qt.ElideRight
        }

        Text {
          anchors.centerIn: parent
          text: textm.elidedText
          font: textm.font
          color: 'cornsilk'
        }
      }
    }
  }

  function lookupBookmarks(queryText) {
    bookmarksModel.findSome(queryText != null ? queryText : "")

    if (bookmarksModel.rowCount() > 0) {
      tableview.selectionModel.setCurrentIndex(
        bookmarksModel.index(0, 0),
        ItemSelectionModel.Select | ItemSelectionModel.Current
      )

      /* Be sure to start at the top */
      tableview.contentY = 0

      bmpopup.open()
      bmpopup.forceActiveFocus()
    }
  }

  onEdited: {
    if (text.length > 0)
      lookupBookmarks(text)
  }

  GemUrlInput {
    id: urlField
    anchors.fill: parent
    anchors.topMargin: 16
    anchors.leftMargin: 16
    onTextEdited: {
      if (text.length > 0) {
        sched.cancel()
        sched.delay(function() {
          edited(text)
        }, editDelay)
      }
    }
    onAccepted: {
      if (!text.startsWith('gemini://')) {
        requested('gemini://' + text)
      } else {
        requested(text)
      }
      sched.cancel()
    }
  }
}
