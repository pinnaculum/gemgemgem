import QtQuick 2.14
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.4

ColumnLayout {
  spacing: 10

  signal closeSettings()

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

  ChoiceCfgSetting {
    id: updatesMode
    dotPath: 'updates.check_updates_mode'
    description: qsTr("Check for updates (AppImage only)")
    choices: [
      'automatic',
      'manual',
      'never'
    ]
  }

  ColumnLayout {
    visible: updatesMode.text === 'manual'
    Button {
      font.bold: true
      font.pointSize: 16
      text: qsTr("Check for updates")
      onClicked: {
        gemalaya.checkUpdates()
        enabled = false

        closeSettings()
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

  ColumnLayout {
    Layout.leftMargin: 25

    Text {
      text: qsTr('Links layout')
      font.pointSize: 16
      font.bold: true
    }

    RowLayout {
      ChoiceCfgSetting {
        id: llMode
        dotPath: 'ui.links.layoutMode'
        description: qsTr("Links layout mode")
        choices: [
          'group',
          'list'
        ]
      }
    }

    RowLayout {
      visible: llMode.text === 'group'
      IntegerCfgSetting {
        dotPath: 'ui.links.gridColumns'
        description: qsTr('Number of columns in the links grid layouts')
        spin.from: 1
        spin.to: 10
        spin.stepSize: 1
      }
    }
    RowLayout {
      visible: llMode.text === 'group'
      IntegerCfgSetting {
        dotPath: 'ui.links.gridRowSpacing'
        description: qsTr('Space between rows in the links grid layouts')
        spin.from: 0
        spin.to: 100
        spin.stepSize: 1
      }
    }

    BooleanCfgSetting {
      visible: llMode.text === 'group'
      dotPath: 'ui.links.gridLimitHeight'
      description: qsTr("Limit grid height (when unfocused)")
    }
    IntegerCfgSetting {
      visible: llMode.text === 'group'
      dotPath: 'ui.links.gridMaxCollapsedHeight'
      description: qsTr('Maximum (collapsed) grid height (px)')
      spin.from: 30
      spin.to: 1000
      spin.stepSize: 10
    }
  }

  Text {
    text: qsTr('Text translation')
    font.pointSize: 20
    font.bold: true
    Layout.fillWidth: true
  }

  RowLayout {
    BooleanCfgSetting {
      id: translation
      dotPath: 'ui.translate.enabled'
      description: qsTr("Enable text translation features")
    }
  }

  ColumnLayout {
    id: tlLayout
    visible: translation.checked
    Layout.leftMargin: 25

    Text {
      text: qsTr('Languages (langs with lowest priority are selected first)')
      font.pointSize: 16
      font.bold: true
    }

    Component.onCompleted: {
      for (let [langTag, cfg] of Object.entries(Conf.ui.translate.targetLangs)) {
        Qt.createComponent('TsLangConfigurator.qml').createObject(
          tlLayout, {
            dotPath: `ui.translate.targetLangs.${langTag}`,
            langTag: langTag
          }
        )
      }
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
        'nanotts',
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
    /*
     * gtts settings
     */

    visible: tts.checked && ttsEngine.text === 'gtts'
    Layout.leftMargin: 25

    Text {
      text: qsTr('gtts options')
      font.pointSize: 18
      font.bold: true
      Layout.fillWidth: true
    }

    RowLayout {
      BooleanCfgSetting {
        dotPath: 'ui.tts.readSlowly'
        description: qsTr("Read the text slowly")
      }
    }
    ChoiceCfgSetting {
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

  ColumnLayout {
    /*
     * nanotts settings
     */

    visible: tts.checked && ttsEngine.text === 'nanotts'
    Layout.leftMargin: 25

    Text {
      text: qsTr('nanotts options')
      font.pointSize: 18
      font.bold: true
      Layout.fillWidth: true
    }

    IntegerCfgSetting {
      dotPath: 'ui.tts.nanotts_options.pitch'
      description: qsTr('Voice pitch (50-200)')
      spin.from: 50
      spin.to: 200
      spin.stepSize: 5
    }
    IntegerCfgSetting {
      dotPath: 'ui.tts.nanotts_options.speed'
      description: qsTr('Voice speed (20-200)')
      spin.from: 20
      spin.to: 200
      spin.stepSize: 2
    }
    IntegerCfgSetting {
      dotPath: 'ui.tts.nanotts_options.volume'
      description: qsTr('Voice volume (20-200)')
      spin.from: 20
      spin.to: 200
      spin.stepSize: 2
    }
  }

  ColumnLayout {
    /* TTS test */

    visible: tts.checked
    Layout.leftMargin: 15

    TextToSpeech {
      id: ttsiface
      onConverted: {
        ttsaudiop.stop()
        ttsaudiop.audioFile = filepath
        ttsaudiop.play()
        ttsTest.enabled = true
      }
    }

    AudioFilePlayer {
      id: ttsaudiop
    }

    Button {
      id: ttsTest
      text: qsTr(`Test TTS settings (${ttsEngine.text})`)
      font.bold: true
      font.pointSize: 16
      onClicked: {
        if (ttsaudiop.playing)
          ttsaudiop.stop()

        ttsiface.save(
          "The Matrix is everywhere. It is all around us. Even now in this very room.", {
          lang: 'en', test: true
        })
        ttsTest.enabled = false
      }
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

  /* Margins */

  IntegerCfgSetting {
    dotPath: 'ui.page.leftMargin'
    description: qsTr('Left margin (px)')
    spin.from: 0
    spin.to: 300
    spin.stepSize: 5
  }
  IntegerCfgSetting {
    dotPath: 'ui.page.rightMargin'
    description: qsTr('Right margin (px)')
    spin.from: 0
    spin.to: 300
    spin.stepSize: 5
  }
  IntegerCfgSetting {
    dotPath: 'ui.page.topMargin'
    description: qsTr('Top margin (px)')
    spin.from: 0
    spin.to: 300
    spin.stepSize: 5
  }
  IntegerCfgSetting {
    dotPath: 'ui.page.bottomMargin'
    description: qsTr('Bottom margin (px)')
    spin.from: 0
    spin.to: 300
    spin.stepSize: 5
  }

  /* Flick settings */
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

  /* Max items per page */
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
