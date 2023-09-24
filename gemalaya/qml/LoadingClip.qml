import QtQuick 2.2
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.4

AnimatedImage {
  source: Conf.themeRsc('loading.gif')
  fillMode: Image.PreserveAspectFit
  playing: false
  Layout.maximumWidth: 32
  Layout.maximumHeight: 32
}

