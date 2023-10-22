import QtQuick 2.2
import QtQuick.Layouts 1.4
import Gemalaya 1.0

RowLayout {
  signal tsSuccess(string text, string langTag)
  signal tsError(string text)

  property bool busy: false

  function runTs(text, options) {
    translator.translate(text, options)
    busy = true
  }

  TextTranslator {
    id: translator
    onTranslateError: {
      tsStatus.text = error
      tsError(error)
      busy = false
    }
    onTranslated: {
      tsSuccess(translatedText, targetLangTag)
      busy = false
    }
  }
  LoadingClip {
    id: loading
    visible: busy
    playing: busy
  }
  Text {
    Layout.leftMargin: 32
    id: tsStatus
    color: 'yellow'
    text: targetLang ? targetLang : qsTr('No translation yet')
    font.pointSize: 18
  }
}
