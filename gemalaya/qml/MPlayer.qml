import QtQuick 2.14
import QtQuick.Layouts 1.4
import QtMultimedia 6.2

Item {
  id: control

  property string source
  property alias mediap: mediap

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
    text: 'Click here to start the video'
    color: 'red'
    font.pointSize: 40
    visible: mediap.playbackState == MediaPlayer.StoppedState
  }

  MouseArea {
    anchors.fill: control
    onClicked: {
      videoOutput.visible = true
      let resolution = mediap.metaData.value(27)

      if (mediap.playing == false)
        mediap.play()
      else
        mediap.pause()
    }
  }

  MediaPlayer {
    id: mediap
    source: control.source
    audioOutput: AudioOutput {}
    videoOutput: videoOutput
  }
}
