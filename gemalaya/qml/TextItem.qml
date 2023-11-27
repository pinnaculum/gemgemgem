import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.4
import Qt5Compat.GraphicalEffects
import QtQuick.Effects
import Gemalaya 1.0

ColumnLayout {
  id: itemLayout

  objectName: 'textItem'

  property string content

  property string textType: 'regular'
  property bool hovered
  property bool quote: false
  property bool ttsBusy: false

  property Item nextLinkItem
  property Item prevLinkItem

  /* Text-to-speech */
  property var vocalizer
  property var speechPlayer
  property string speechAudioFp
  property string ttsIconColor: 'transparent'

  /* TS */
  property TranslatorBox tsBox
  property bool wantTs: false
  property string tsContent
  property var translations: {'en': ''}
  property var targetLangs: gemalaya.tsTargetLangCodes()
  property string srcLangTag: gemalaya.langDetect(content)
  property string targetLang: targetLangs.length > 0 ? targetLangs[0] : 'en'

  property int origWidth
  property int origHeight

  property string colorDefault: Conf.text.color
  property string colorPreformatted: Conf.text.colorPreformatted
  property string colorHovered: Conf.text.focusZoom.color
  property string colorizationColor: Conf.text.focusZoom.colorizationColor

  KeyNavigation.backtab: prevLinkItem
  KeyNavigation.priority: KeyNavigation.BeforeItem
  KeyNavigation.tab: nextLinkItem
  Layout.maximumWidth: width
  Layout.fillWidth: true

  signal focusRequested()

  Scheduler {
    id: sched
  }

  Action {
    enabled: (itemLayout.focus && itemLayout.visible) && speechPlayer !== undefined
    shortcut: 'r'
    onTriggered: {
      if (!speechPlayer.playing) {
        speechPlayer.play()
      } else {
        speechPlayer.stop()
        speechPlayer.play()
      }
    }
  }
  Action {
    enabled: (itemLayout.focus && itemLayout.visible) && speechPlayer !== undefined
    shortcut: 'Left'
    onTriggered: {
      if (speechPlayer.playing) {
        speechPlayer.position -= 3000
      }
    }
  }

  Action {
    enabled: (itemLayout.focus && itemLayout.visible) && speechPlayer !== undefined
    shortcut: 'Right'
    onTriggered: {
      if (speechPlayer && speechPlayer.playing) {
        speechPlayer.position += 3000
      }
    }
  }

  Action {
    enabled: (itemLayout.focus && itemLayout.visible) && speechPlayer !== undefined
    shortcut: 'Space'
    onTriggered: {
      if (speechPlayer.playing) {
        speechPlayer.pause()
      } else {
        speechPlayer.play()
      }
    }
  }
  Action {
    enabled: (itemLayout.focus && itemLayout.visible) && speechPlayer !== undefined
    shortcut: Conf.ui.ttsPlayerShortcuts.playbackRateIncrease
    onTriggered: {
      if (speechPlayer.playing) {
        speechPlayer.playbackRate += 0.1
      }
    }
  }
  Action {
    enabled: (itemLayout.focus && itemLayout.visible) && speechPlayer !== undefined
    shortcut: Conf.ui.ttsPlayerShortcuts.playbackRateDecrease
    onTriggered: {
      if (speechPlayer.playbackRate > 0.2) {
        speechPlayer.playbackRate -= 0.1
      }
    }
  }

  Action {
    enabled: (itemLayout.focus && itemLayout.visible) &&
             Conf.ui.translate.enabled
    shortcut: Conf.ui.textItemShortcuts.translateText
    onTriggered: {
      wantTs = !wantTs

      if (wantTs) {
        /* Use the first language in the target list */
        targetLang = targetLangs[0]
      }

      if (tsBox === null) {
        /* Create the ts component */
        tsBox = Qt.createComponent('TranslatorBox.qml').createObject(
          tsLayout, {}
        )
        tsBox.tsSuccess.connect(function(text, langTag) {
          tsContent = text
          translations[langTag] = text
          targetLang = langTag

          if (vocalizer !== undefined) {
            vocalizer.text = text
            vocalizer.get()
          }
        })
      }

      tsBox.runTs(content, {dstlang: targetLang})
    }
  }

  Action {
    enabled: (itemLayout.focus && itemLayout.visible && wantTs) &&
             Conf.ui.translate.enabled
    shortcut: Conf.ui.textItemShortcuts.translateChangeLanguage
    onTriggered: {
      if (tsBox === null)
        return

      let clidx = targetLangs.indexOf(targetLang)

      if (clidx === -1 || clidx >= targetLangs.length - 1)
        targetLang = targetLangs[0]
      else
        targetLang = targetLangs[clidx+1]

      if (translations[targetLang]) {
        tsContent = translations[targetLang]
      } else {
        tsBox.runTs(content, {dstlang: targetLang})
      }
    }
  }

  Component.onDestruction: {
    /* Make sure we stop the TTS player and destroy it */
    if (speechPlayer !== undefined) {
      speechPlayer.stop()
      speechPlayer.destroy()
    }
  }

  onFocusChanged: {
    /* Text-to-speech for regular text */

    if (Conf.ui.tts.enabled && (textType === 'regular' || textType === 'quote') &&
       (!vocalizer && !speechAudioFp)) {

      /* Instantiate the vocalizer */
      vocalizer = Qt.createComponent('TextVocalizer.qml').createObject(this, {
        text: tsContent.length > 0 ? tsContent : content
      })

      vocalizer.convertError.connect(function(error) {
        ttsError.text = error
        ttsBusy = false
        ttsIconColor = 'red'
      })

      vocalizer.converted.connect(function(audioFp) {
        speechAudioFp = audioFp
        ttsBusy = false
        ttsIconColor = 'darkorange'

        if (speechPlayer === undefined) {
          speechPlayer = Qt.createComponent('AudioFilePlayer.qml').createObject(
            itemLayout, {
              audioFile: speechAudioFp,
              playbackRate: Conf.ui.tts.playbackRate
            })
        } else {
          /* TTS player already loaded, change the audio file
           * (this would happen when we translate the text to another language)
           */

          speechPlayer.audioFile = speechAudioFp

          console.log('Audio file changed, target lang is: ' + targetLang)
        }

        if (Conf.ui.tts.autoPlay && focus) {
          /* Play it right away if autoplay is enabled and we're still focused */
          speechPlayer.play()
        }
      })

      ttsBusy = true
      ttsIconColor = 'cyan'

      vocalizer.get()
    }

    /* Is the speech player already loaded ? */
    if (speechPlayer !== undefined) {
      if (!focus) {
        /* Unfocused now, pause the TTS */
        speechPlayer.pause()
      }
    }

    if (!Conf.text.focusZoom.enabled)
      return

    if (focus) {
      origWidth = width

      sched.delay(function() { sanimin.running = true }, Conf.text.focusZoom.timeout)
    } else {
      sched.cancel()
      sanimout.running = true
    }
  }

  Label {
    id: control

    Layout.margins: 10
    Layout.leftMargin: textType == 'listitem' || quote ? 30 : 10
    Layout.bottomMargin: textType == 'listitem' ? 15 : 10
    Layout.fillWidth: true
    Layout.alignment: quote ? Qt.AlignHCenter : Qt.AlignLeft

    function tsConv(st) {
      /* Convert text st as a string name (from the config) to Qt values */
      if (st == 'normal')
        return Text.Normal
      else if (st == 'outline')
        return Text.Outline
      else if (st == 'raised')
        return Text.Raised
      else if (st == 'sunken')
        return Text.Sunken
      else
        return Text.Normal
    }

    function searchText(stext) {
      return content.search(stext) != -1
    }

    layer.enabled: activeFocus
    layer.effect: MultiEffect {
      id: multiEffect
      shadowEnabled: false
      shadowHorizontalOffset: 10
      shadowVerticalOffset: 10
      colorizationColor: Conf.text.focusZoom.colorizationColor
      colorization: Conf.text.focusZoom.colorization
      brightness: Conf.text.focusZoom.brightness
      contrast: Conf.text.focusZoom.contrast
    }

    TextMetrics {
      id: textmn
      font.family: textType == "preformatted" ? "Courier" : Conf.text.fontFamily
      font.pointSize: {
        if (textType == "preformatted")
          return Conf.fontPrefs.preformattedText.pointSize

        return Conf.fontPrefs.text.pointSize ? Conf.fontPrefs.text.pointSize : Conf.fontPrefs.defaultPointSize
      }
      font.italic: quote === true
      text: tsContent ? tformat(tsContent) : tformat(content)

      function tformat(itext) {
        return textType == 'listitem' ? '- ' + itext : itext
      }
    }

    background: Rectangle {
      color: 'transparent'
    }

    color: textType == "preformatted" ? colorPreformatted : colorDefault
    text: textmn.text
    font: textmn.font
    lineHeight: textType == "preformatted" ? 1 : Conf.text.lineHeight
    renderType: Text.NativeRendering
    antialiasing: true
    wrapMode: textType == "preformatted" ? Text.WrapAnywhere : Text.WordWrap

    SequentialAnimation {
      /* Animation for when the text's being focused */
      id: sanimin

      PropertyAnimation {
        target: control
        property: 'font.pointSize'
        from: control.font.pointSize
        to: textmn.font.pointSize * 1.1
        duration: 0
      }
      PropertyAnimation {
        target: control
        property: 'font.wordSpacing'
        from: control.font.wordSpacing
        to: Conf.text.focusZoom.fontWordSpacing ? Conf.text.focusZoom.fontWordSpacing : 4
        duration: 0
      }
      PropertyAnimation {
        target: control
        property: 'color'
        from: control.color
        to: colorHovered
        duration: 0
      }

      PropertyAnimation {
        target: control
        property: 'Layout.margins'
        from: 10
        to: 15
        duration: 0
      }
    }

    SequentialAnimation {
      /* Animation for when the mouse is moved out of the text */
      id: sanimout

      PropertyAnimation {
        target: control
        property: 'font.pointSize'
        from: control.font.pointSize
        to: textmn.font.pointSize
        duration: 10
      }
      PropertyAnimation {
        target: control
        property: 'font.wordSpacing'
        from: control.font.wordSpacing
        to: Conf.text.fontWordSpacing ? Conf.text.fontWordSpacing : 4
        duration: 10
      }
      PropertyAnimation {
        target: control
        property: 'color'
        from: control.color
        to: colorDefault
        duration: 10
      }
      PropertyAnimation {
        target: control
        property: 'Layout.margins'
        from: 20
        to: 10
        duration: 10
      }
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onEntered: {
        hovered = true
      }
      onExited: {
        hovered = false
      }
      onClicked: itemLayout.focus = !itemLayout.focus
    }
  }

  RowLayout {
    id: tsLayout
    visible: wantTs
  }

  /* Layout that contains the text-to-speech controls */
  RowLayout {
    visible: Conf.ui.tts.enabled && itemLayout.focus &&
      (textType === 'regular' || textType === 'quote')

    LoadingClip {
      visible: ttsBusy
      playing: ttsBusy
    }
    ToolButton {
      icon.source: Conf.themeRsc('tts.png')
      icon.color: ttsIconColor
      icon.width: 64
      icon.height: 64
      visible: Conf.ui.tts.enabled && (ttsBusy || itemLayout.focus)
    }
    Text {
      id: ttsError
      visible: Conf.ui.tts.enabled && itemLayout.focus && text.length > 0
      color: 'red'
      font.pointSize: 20
    }
    ProgressBar {
      from: 0
      to: speechPlayer !== undefined ? speechPlayer.duration : 0
      value: speechPlayer !== undefined ? speechPlayer.position : 0
      background: Rectangle {
        color: 'transparent'
      }
      Layout.fillWidth: true
    }
  }
}
