import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.4
import Qt.labs.platform

ColumnLayout {
  id: root

  property string sendUrl
  property string promptText

  property ColumnLayout pageLayout

  property string colorDefault: 'cornsilk'
  property string colorHovered: 'white'

  /* List of words learned from the previous page */
  property var words: []

  signal sendRequest(url sendUrl, string inputValue)

  function focusInput() {
    input.forceActiveFocus()
  }

  spacing: 30
  Layout.fillWidth: true
  Layout.preferredWidth: width

  Menu {
    id: wordsMenu
    Component.onCompleted: {
      words.forEach(function(word) {
        const item = Qt.createQmlObject(`
          import Qt.labs.platform

          MenuItem {
            text: "${word}"
            onTriggered: menu.wordSelected(text)
          }
        `, wordsMenu, "wordMenuItem")

        wordsMenu.addItem(item)
      })
    }

    signal wordSelected(string word)

    onWordSelected: {
      input.insert(input.cursorPosition, word)
    }
  }

  Text {
    text: qsTr('Input request: ') + promptText
    color: colorDefault
    font.pointSize: 20
    font.bold: true
    Layout.fillWidth: true
    horizontalAlignment: Text.AlignHCenter
    wrapMode: TextEdit.WordWrap
  }

  RowLayout {
    visible: snippetsModel.count > 0
    spacing: 30

    Text {
      text: qsTr('Load a stored snippet (' + snippetLoadAction.shortcut + ')')
      color: colorDefault
      font.pointSize: 18
      horizontalAlignment: Text.AlignHCenter
    }

    ComboBox {
      id: snippetsCombo
      textRole: 'name'
      model: ListModel {
        id: snippetsModel
      }

      KeyNavigation.tab: input

      background: Rectangle {
        implicitWidth: 150
        implicitHeight: 40
        border.color: parent.pressed ? "#17a81a" : "#21be2b"
        border.width: parent.visualFocus ? 2 : 1
        radius: 2
      }

      Component.onCompleted: {
        for (var snippet of gemalaya.inputSnippets()) {
          snippetsModel.append({name: snippet.name, content: snippet.text})
        }
        currentIndex = 0
      }

      onActivated: {
        var snippet = snippetsModel.get(index)

        input.text = snippet.content
        input.moveCursorSelection
        input.forceActiveFocus()
      }
    }
  }

  /* Action to load a snipper in the text area */
  Action {
    id: snippetLoadAction
    shortcut: 'Ctrl+s'
    onTriggered: {
      snippetsCombo.popup.open()
      snippetsCombo.forceActiveFocus()
    }
  }

  /* Action to insert a word found in the previous page */
  Action {
    shortcut: 'Ctrl+i'
    onTriggered: {
      wordsMenu.open(input, null)
    }
  }

  Flickable {
    contentWidth: input.paintedWidth
    contentHeight: input.paintedHeight
    clip: true

    Layout.fillWidth: true
    Layout.minimumHeight: root.height * 0.55
    Layout.maximumHeight: root.height * 0.65
    Layout.margins: 30

    ScrollBar.vertical: ScrollBar {
      policy: ScrollBar.AlwaysOn
      width: 15
    }

    TextArea.flickable: TextArea {
      id: input
      wrapMode: TextEdit.WrapAnywhere
      selectByMouse: true
      focus: true
      textMargin: 10

      KeyNavigation.tab: sendButton

      Keys.onTabPressed: {
        /* Focus the send button manually when Tab is pressed here */
        if (text.length > 0)
          sendButton.focus = true
      }

      font.pointSize: 18
      font.family: "Segoe UI"

      color: colorDefault
      selectionColor: "steelblue"
      selectedTextColor: "#eee"

      padding: 15

      background: Rectangle {
        color: "#323532"
        border.color: "#4a9ea1"
      }
    }
  }

  RowLayout {
    SendButton {
      id: sendButton
      Layout.alignment: Qt.AlignHCenter
      Layout.leftMargin: 32
      text: qsTr('Send')
      KeyNavigation.tab: sendAndSave

      onClicked: {
        if (input.text.length > 0) {
          var urlObject = new URL(
            sendUrl + '?' + encodeURIComponent(input.text))

          sendRequest(urlObject, input.text)
        } else {
          focusInput()
        }
      }
    }

    SendButton {
      id: sendAndSave
      Layout.alignment: Qt.AlignHCenter
      text: qsTr('Send and save as snippet')
      onClicked: {
        if (input.text.length > 0) {
          snippetName.focus = true
        } else {
          focusInput()
        }
      }
    }
    Text {
      text: qsTr('Snippet name')
      font.pointSize: 22
      color: colorDefault
      visible: snippetName.activeFocus
    }
    TextField {
      id: snippetName
      font.pointSize: 22
      Layout.minimumWidth: 220
      visible: activeFocus
      onAccepted: {
        var urlObject = new URL(
          sendUrl + '?' + encodeURIComponent(input.text))

        gemalaya.inputSnippetSave(text, input.text, true)

        sendRequest(urlObject, input.text)
      }
    }
  }

  Text {
    text: qsTr("Hint: once you've finished writing, press the Tab key to focus the send button")
    color: colorDefault
    horizontalAlignment: Text.AlignHCenter
    font.pointSize: 16
    font.italic: true
    Layout.fillWidth: true
  }
}
