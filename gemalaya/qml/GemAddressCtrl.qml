import QtQuick 2.2
import QtQuick.Controls 2.4
import Qt.labs.qmlmodels 1.0

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

  function histAdd(url) {
    if (!history.includes(url)) {
      history.push(url)
    }
  }
  function histPop() {
    if (history.length > 1) {
      let old = history.pop()

      if (history.length > 0)
        return history[history.length - 1]
    }
  }

  function focusInput() {
    input.forceActiveFocus()
  }

  Scheduler {
    id: sched
  }

  Keys.onEscapePressed: {
    hovered = false
    sched.cancel()
    hidden()
  }

  Action {
    id: focusAction
    shortcut: Conf.shortcuts.urlEdit
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
      urlField.forceActiveFocus()
      sched.cancel()
    }
    onExited: hovered = false
  }

  Rectangle {
    anchors.fill: parent
    color: '#2f4f4f'
    border.width: 1
    border.color: 'lightsteelblue'
  }

  ListModel {
    id: bookmarksm

    Component.onCompleted: {
      Conf.c.bookmarks.forEach(function(bmark) {
        append(bmark)
      })
    }
  }

  Popup {
    id: bmpopup
    width: control.width
    height: 250
    x: urlField.x
    y: urlField.y + urlField.height
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
    background: Rectangle {
      color: '#2f4a3f'
      border.width: 1
      border.color: 'black'
    }

    contentItem: TableView {
      id: tableview
      focus: true
      clip: true
      model: bookmarksModel
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
        implicitHeight: 32
        color: current ? 'blue' : 'transparent'

        TextMetrics {
          id: textm
          font.family: 'Courier'
          font.pointSize: 16
          font.bold: column == 0
          text: display
          elideWidth: del.width * 0.9
          elide: Qt.ElideRight
        }

        Text {
          anchors.centerIn: parent
          text: textm.elidedText
          font: textm.font
        }
      }
    }
  }

  onEdited: {
    bookmarksModel.findSome(text)

    if (bookmarksModel.rowCount() > 0) {
      tableview.selectionModel.setCurrentIndex(
        bookmarksModel.index(0, 0),
        ItemSelectionModel.Select | ItemSelectionModel.Current
      )

      bmpopup.open()
      bmpopup.forceActiveFocus()
    }
  }

  GemUrlInput {
    id: urlField
    padding: 20
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
      requested(text)
      sched.cancel()
    }
  }
}
