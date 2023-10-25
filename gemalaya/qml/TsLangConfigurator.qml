import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.4

RowLayout {
  property string dotPath
  property string langTag

  CheckBox {
    property string dp: dotPath + '.enabled'
    font.pointSize: 14
    text: langTag
    checked: Conf.get(dp)

    onCheckStateChanged: {
      Conf.set(dp, checked)
    }
  }

  Text {
    font.pointSize: 16
    font.bold: true
    text: qsTr('Priority')
  }

  SpinBox {
    id: spinbox
    property string dp: dotPath + '.prio'
    Layout.minimumWidth: 100
    Layout.maximumWidth: 130
    Layout.minimumHeight: 32
    font.pointSize: 16
    from: 1
    to: 100
    value: Conf.get(dp)
    onValueModified: {
      Conf.set(dp, value)
    }
  }
}
