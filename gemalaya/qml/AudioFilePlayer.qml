import QtQuick 2.15
import QtMultimedia 6.2

MediaPlayer {
  property string audioFile
  audioOutput: AudioOutput {}
  source: "file://" + audioFile
}
