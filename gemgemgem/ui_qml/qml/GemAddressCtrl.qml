import QtQuick 2.2
import QtQuick.Controls 2.4
import Qt.labs.qmlmodels 1.0

Item {
  id: control
  property int editDelay: 500
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
    shortcut: 'Ctrl+L'
    onTriggered: {
      urlField.forceActiveFocus()
      urlField.selectAll()
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onEntered: {
      hovered = true
      urlField.forceActiveFocus()
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
    x: control.x
    y: control.y + control.height
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
    background: Rectangle {
      color: 'lightgray'
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
        implicitWidth: 300
        implicitHeight: 32
        color: current ? 'blue' : 'transparent'
        Text {
          anchors.centerIn: parent
          text: display
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          onClicked: {
            var data = bookmarksModel.getFromRow(tableview.currentRow)
          }
        }
      }
    }
  }

  onEdited: {
    bookmarksModel.findSome(text)
    console.log(bookmarksModel.rowCount())

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
      sched.cancel()
      sched.delay(function() {
        edited(text)
      }, editDelay)
    }
    onAccepted: {
      requested(text)
    }
  }
}
