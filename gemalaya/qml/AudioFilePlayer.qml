import QtQuick 2.15
import QtMultimedia 6.2

MediaPlayer {
  property string audioFile
  audioOutput: AudioOutput {}
  source: "file://" + audioFile

  signal playFinished()

  onPositionChanged: {
    /* Emit playFinished if we've played the whole audio file */
    if (position === duration)
      playFinished()
  }
}
