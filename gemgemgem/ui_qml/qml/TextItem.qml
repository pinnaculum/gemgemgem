import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.4

Text {
  id: control

  property string content
  property bool hovered
  property bool quote: false

  property int origWidth
  property int origHeight

  property int pointSizeNormal: 18
  property int pointSizeLarge: 20

  property string colorDefault: 'cornsilk'
  property string colorHovered: 'white'

  Layout.margins: 10
  Layout.maximumWidth: width
  Layout.alignment: quote ? Qt.AlignHCenter : Qt.AlignLeft
  width: width

  signal focusRequested()

  TextMetrics {
    id: textmn
    font.family: "DejaVuSans"
    font.pointSize: pointSizeNormal
    font.italic: quote === true
    text: content
  }

  TextMetrics {
    id: textml
    font.family: "DejaVuSans"
    font.pointSize: pointSizeLarge
    text: content
  }

  color: colorDefault
  text: textmn.text
  font: textmn.font
  lineHeight: 1.1
  renderType: Text.NativeRendering

  antialiasing: true
  wrapMode: Text.WordWrap

  Scheduler {
    id: sched
  }

  onHoveredChanged: {
    if (hovered) {
      origWidth = width

      sched.delay(function() { sanimin.running = true }, 500)
    } else {
      sched.cancel()
      sanimout.running = true
    }
  }

  SequentialAnimation {
    /* Animation for when the text's hovered with the mouse */
    id: sanimin

    PropertyAnimation {
      target: control
      property: 'height'
      from: control.height
      to: control.height * 1.2
      duration: 10
    }
    PropertyAnimation {
      target: control
      property: 'width'
      from: control.width
      to: control.width * 0.9
      duration: 10
    }
    PropertyAnimation {
      target: control
      property: 'font.pointSize'
      from: control.font.pointSize
      to: pointSizeLarge
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
      to: control.lineHeight + 0.1
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
      property: 'height'
      from: control.height
      to: control.height * 0.8
      duration: 30
    }
    PropertyAnimation {
      target: control
      property: 'width'
      from: control.width
      to: origWidth
      duration: 30
    }
    PropertyAnimation {
      target: control
      property: 'font.pointSize'
      from: control.font.pointSize
      to: pointSizeNormal
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

  onFocusRequested: hovered = true

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onEntered: {
      hovered = true
    }
    onExited: {
      hovered = false
    }
  }
}
