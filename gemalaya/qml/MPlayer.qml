import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.4
import QtMultimedia 6.2

Item {
  id: control

  property string source
  property alias mediap: mediap

  property int desiredVideoHeight

  Layout.preferredHeight: mediap.hasVideo ? desiredVideoHeight : 128

  onVisibleChanged: {
    if (!visible)
      mediap.pause()
  }

  Action {
    id: playAction
    shortcut: 'p'
    enabled: control.visible
    onTriggered: {
      videoOutput.visible = true

      if (mediap.playing == false)
        mediap.play()
      else
        mediap.pause()
    }
  }

  Action {
    id: stopAction
    shortcut: 's'
    enabled: control.visible
    onTriggered: {
      mediap.stop()
    }
  }

  Action {
    shortcut: 'Right'
    enabled: control.visible
    onTriggered: {
      if (mediap.playing == true) {
        mediap.position += 3000
      }
    }
  }

  Action {
    shortcut: 'Ctrl+Right'
    enabled: control.visible
    onTriggered: {
      if (mediap.playing == true) {
        mediap.position += 10000
      }
    }
  }

  Action {
    shortcut: 'Left'
    enabled: control.visible
    onTriggered: {
      if (mediap.playing == true) {
        mediap.position -= 3000
      }
    }
  }

  Action {
    shortcut: 'Ctrl+Left'
    enabled: control.visible
    onTriggered: {
      if (mediap.playing == true) {
        mediap.position -= 10000
      }
    }
  }

  VideoOutput {
    id: videoOutput
    anchors.top: control.top
    width: control.width
    height: control.height
    visible: false
  }

  Text {
    anchors.fill: control
    anchors.centerIn: control
    text: qsTr('Click here or press "p" to start the audio/video')
    color: 'red'
    font.pointSize: 32
    visible: mediap.playbackState !== MediaPlayer.PlayingState
  }

  MouseArea {
    anchors.fill: control
    onClicked: {
      playAction.trigger()
    }
  }

  MediaPlayer {
    id: mediap
    source: control.source
    audioOutput: AudioOutput {}
    videoOutput: videoOutput
  }
}
