import QtQuick 2.14
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.4

ColumnLayout {
  RowLayout {
    Text {
      text: qsTr('Theme')
      font.pointSize: 16
      font.bold: true
      Layout.fillWidth: true
    }

    ComboBox {
      model: Conf.themesNames
      displayText: Conf.c.ui.theme
      Layout.minimumWidth: 200
      Layout.minimumHeight: 64
      font.pointSize: 14
      onActivated: {
        Conf.changeTheme(currentText)
      }
    }
  }

  Text {
    text: qsTr('Links')
    font.pointSize: 20
    font.bold: true
    Layout.fillWidth: true
  }

  RowLayout {
    BooleanCfgSetting {
      dotPath: 'ui.showLinkUrl'
      description: qsTr("Show the link's URL (when a link is focused)")
    }
  }

  Text {
    text: qsTr('Text to speech')
    font.pointSize: 20
    font.bold: true
    Layout.fillWidth: true
  }

  RowLayout {
    BooleanCfgSetting {
      id: tts
      dotPath: 'ui.tts.enabled'
      description: qsTr("Enable text-to-speech (TTS) conversion and audio playing")
    }
  }

  ColumnLayout {
    enabled: tts.checked

    ChoiceCfgSetting {
      id: ttsEngine
      dotPath: 'ui.tts.engine'
      description: qsTr("Text-to-speech engine")
      choices: [
        'picotts',
        'gtts'
      ]

      onChanged: {
        if (chosen === 'gtts') {
          /* Show a privacy warning if the user chooses gtts */

          const wdialog = Qt.createComponent('PrivacyWarningDialog.qml').createObject(
            this, {
              warning: "gTTS uses Google Translate’s text-to-speech services.\n" +
              "If you use this TTS engine, the text content of the gemini page will be sent to Google's servers to be converted to a speech audio file.\n" +
              "If you are concerned about your privacy (as you should be), please use an offline TTS engine like Pico TTS !"
          })
          wdialog.open()
        }
      }
    }
    RowLayout {
      BooleanCfgSetting {
        dotPath: 'ui.tts.autoPlay'
        description: qsTr("Automatically play audio after conversion")
      }
    }
    IntegerCfgSetting {
      dotPath: 'ui.tts.mp3CacheForDays'
      description: qsTr('Maximum lifetime (in days) for cached TTS audio files')
      spin.from: 0
      spin.to: 365 * 3
      spin.stepSize: 1
    }
  }

  ColumnLayout {
    enabled: tts.checked && ttsEngine.text === 'gtts'

    Text {
      Layout.leftMargin: 25
      text: qsTr('gtts options')
      font.pointSize: 18
      font.bold: true
      Layout.fillWidth: true
    }

    RowLayout {
      BooleanCfgSetting {
      Layout.leftMargin: 35
        dotPath: 'ui.tts.readSlowly'
        description: qsTr("Read the text slowly")
      }
    }
    ChoiceCfgSetting {
      Layout.leftMargin: 35
      dotPath: 'ui.tts.defaultTld'
      description: qsTr("Default TLD domain (localized accent)")
      choices: [
        'ca',
        'com',
        'co.uk',
        'ie',
        'co.za',
        'com.mx',
        'es',
        'com.au',
        'us',
        'fr'
      ]
    }
  }

  Text {
    text: qsTr('Timers')
    font.bold: true
    font.pointSize: 20
  }
  IntegerCfgSetting {
    dotPath: 'ui.urlCompletionTimeout'
    description: qsTr('URL completion timeout')
    spin.stepSize: 50
  }
  IntegerCfgSetting {
    dotPath: 'ui.keybSeqTimeout'
    description: qsTr('Keyboard sequence timeout')
    spin.stepSize: 50
  }

  Text {
    text: qsTr('Page')
    font.bold: true
    font.pointSize: 20
  }

  IntegerCfgSetting {
    dotPath: 'ui.page.flickDeceleration'
    description: qsTr('Page flick deceleration')
    spin.stepSize: 10
  }

  IntegerCfgSetting {
    dotPath: 'ui.page.maximumFlickVelocity'
    description: qsTr('Maximum page flick velocity (in pixels per second)')
    spin.from: 10
    spin.to: 10000
    spin.stepSize: 50
  }
  IntegerCfgSetting {
    dotPath: 'ui.page.downFlickPPS'
    description: qsTr('How much to flick when "down" is pressed (in pps)')
    spin.from: -1000
    spin.to: 0
    spin.stepSize: 50
  }
  IntegerCfgSetting {
    dotPath: 'ui.page.upFlickPPS'
    description: qsTr('How much to flick when "up" is pressed (in pps)')
    spin.from: 10
    spin.to: 10000
    spin.stepSize: 50
  }
  IntegerCfgSetting {
    dotPath: 'ui.page.pageDownFlickPPS'
    description: qsTr('How much to flick when "page down" is pressed (in pps)')
    spin.from: -5000
    spin.to: 0
    spin.stepSize: 50
  }
  IntegerCfgSetting {
    dotPath: 'ui.page.pageUpFlickPPS'
    description: qsTr('How much to flick when "page up" is pressed (in pps)')
    spin.from: 10
    spin.to: 10000
    spin.stepSize: 50
  }
  IntegerCfgSetting {
    dotPath: 'ui.page.maxItemsPerPageSection'
    description: qsTr('Maximum items rendered per page section')
    spin.from: 32
    spin.to: 8192
    spin.stepSize: 16
  }

  Text {
    text: qsTr('Fonts')
    font.bold: true
    font.pointSize: 20
  }

  IntegerCfgSetting {
    dotPath: 'ui.fonts.links.pointSize'
    description: qsTr('Font size for links')
    spin.from: 8
    spin.to: 42
    spin.stepSize: 1
  }

  IntegerCfgSetting {
    dotPath: 'ui.fonts.links.shortcutFontSize'
    description: qsTr('Font size for the links shortcut indicators')
    spin.from: 8
    spin.to: 42
    spin.stepSize: 1
  }

  IntegerCfgSetting {
    dotPath: 'ui.fonts.text.pointSize'
    description: qsTr('Font size for normal text')
    spin.from: 8
    spin.to: 42
    spin.stepSize: 1
  }

  IntegerCfgSetting {
    dotPath: 'ui.fonts.preformattedText.pointSize'
    description: qsTr('Font size for preformatted text')
    spin.from: 8
    spin.to: 42
    spin.stepSize: 1
  }
}
