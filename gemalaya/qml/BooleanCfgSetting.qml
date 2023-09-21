import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.4

RowLayout {
  property string dotPath
  property string description
  property alias checkbox: checkbox

  CheckBox {
    id: checkbox
    text: description
    checked: Conf.get(dotPath)
    Layout.fillWidth: true
    Layout.fillHeight: true
    font.pointSize: 14
    onCheckStateChanged: {
      Conf.set(dotPath, checked)
    }
  }
}
