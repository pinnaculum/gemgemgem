import QtCore
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Window

Window {
  id: win

  property url titanUrl

  width: 420
  height: 340
  visible: true
  modality: Qt.ApplicationModal
  title: qsTr("Select a file to upload")

  signal selected(string path)

  FileDialog {
    id: fileDialog
    currentFolder: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
    visible: true
    onAccepted: {
      var path = selectedFile.toString().replace('file://', '')

      fileDialog.done(0)
      win.close()

      selected(path)
    }

    onRejected: {
      win.close()
    }
  }
}
