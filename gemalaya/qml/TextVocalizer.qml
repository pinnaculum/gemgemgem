import QtQuick 2.15
import Gemalaya 1.0

TextToSpeech {
  property string language: gemalaya.langDetect(text)
  property string text

  function get() {
    save(text, {
      lang: language,
      slow: Conf.ui.tts.readSlowly,
      tld: Conf.ui.tts.defaultTld
    })
  }
}
