import QtQuick 2.2
import QtQuick.Dialogs

MessageDialog {
  property string warning
  text: qsTr("PRIVACY WARNING")
  informativeText: warning
  buttons: MessageDialog.Ok
}
