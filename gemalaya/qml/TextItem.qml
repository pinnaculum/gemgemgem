import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.4

Label {
  id: control

  property string content
  property string textType: 'regular'
  property bool hovered
  property bool quote: false

  property Item nextLinkItem
  property Item prevLinkItem

  property int origWidth
  property int origHeight

  property string colorDefault: Conf.text.color
  property string colorHovered: Conf.text.focusZoom.color

  KeyNavigation.backtab: prevLinkItem
  KeyNavigation.priority: KeyNavigation.BeforeItem
  KeyNavigation.tab: nextLinkItem

  Layout.margins: 10
  Layout.leftMargin: textType == 'listitem' ? 30 : 10
  Layout.bottomMargin: textType == 'listitem' ? 15 : 10
  Layout.maximumWidth: width
  Layout.fillWidth: true
  Layout.alignment: quote ? Qt.AlignHCenter : Qt.AlignLeft

  signal focusRequested()

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

  TextMetrics {
    id: textmn
    font.family: textType == "preformatted" ? "Courier" : Conf.text.fontFamily
    font.pointSize: {
      if (textType == "preformatted")
        return Conf.fontPrefs.preformattedText.pointSize

      return Conf.fontPrefs.text.pointSize ? Conf.fontPrefs.text.pointSize : Conf.fontPrefs.defaultPointSize
    }
    font.italic: quote === true
    text: textType == 'listitem' ? '- ' + content : content
  }

  background: Rectangle {
    color: 'transparent'
  }

  color: colorDefault
  text: textmn.text
  font: textmn.font
  lineHeight: textType == "preformatted" ? 1 : Conf.text.lineHeight
  renderType: Text.NativeRendering
  antialiasing: true
  wrapMode: textType == "preformatted" ? Text.NoWrap : Text.WordWrap

  /*
  Setting style to anything else than Text.Normal randomly crashes
  the app with an malloc() message :\

  style: {
    if ((focus || hovered) && Conf.text.focusZoom.style) {
      return tsConv(Conf.text.focusZoom.style)
    } else if (Conf.text.style) {
      return tsConv(Conf.text.style)
    } else {
      return Text.Normal
    }
  }

  styleColor: focus || hovered ? Conf.text.focusZoom.styleColor : Conf.text.styleColor
  */

  Scheduler {
    id: sched
  }

  onFocusChanged: {
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

  SequentialAnimation {
    /* Animation for when the text's being focused */
    id: sanimin

    PropertyAnimation {
      target: control
      property: 'font.pointSize'
      from: control.font.pointSize
      to: textmn.font.pointSize * 1.2
      duration: 10
    }
    PropertyAnimation {
      target: control
      property: 'font.wordSpacing'
      from: control.font.wordSpacing
      to: Conf.text.focusZoom.fontWordSpacing ? Conf.text.focusZoom.fontWordSpacing : 4
      duration: 10
    }
    PropertyAnimation {
      target: control
      property: 'color'
      from: control.color
      to: colorHovered
      duration: 10
    }
    PropertyAnimation {
      target: control
      property: 'lineHeight'
      from: control.lineHeight
      to: Conf.text.focusZoom.lineHeight ? Conf.text.focusZoom.lineHeight : control.lineHeight + 0.1
      duration: 10
    }

    PropertyAnimation {
      target: control
      property: 'Layout.margins'
      from: 10
      to: 20
      duration: 10
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
      property: 'lineHeight'
      from: control.lineHeight
      to: 1.1
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
    onClicked: control.focus = !control.focus
  }
}
