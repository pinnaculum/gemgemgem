import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.4

import ".."

RowLayout {
  property string name
  property string shortcut

  property alias keyseq: keyseq

  spacing: 20

  Text {
    text: name
    font.pointSize: 18
    Layout.fillWidth: true
  }

  KeySeqCaptureField {
    id: keyseq
    currentShortcut: shortcut
    focus: true
    onModified: {
      Conf.set(`ui.shortcuts.${name}`, shortcutText)
      Conf.update()
    }
  }
}
