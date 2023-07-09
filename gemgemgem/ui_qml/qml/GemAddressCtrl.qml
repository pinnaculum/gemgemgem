import QtQuick 2.2
import QtQuick.Controls 2.4

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
      // clear()
    }
  }
}
