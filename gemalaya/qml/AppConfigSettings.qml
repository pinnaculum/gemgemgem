import QtQuick 2.14
import QtQuick.Layouts 1.4

ColumnLayout {
  IntegerCfgSetting {
    dotPath: 'ui.urlCompletionTimeout'
    description: qsTr('URL completion timeout')
    spin.stepSize: 50
  }
  IntegerCfgSetting {
    dotPath: 'ui.keybSeqTimeout'
    description: qsTr('Keyboard sequence timeout')
    spin.stepSize: 50
  }

  Text {
    text: qsTr('Page')
    font.bold: true
    font.pointSize: 20
  }

  IntegerCfgSetting {
    dotPath: 'ui.page.flickDeceleration'
    description: qsTr('Page flick deceleration')
    spin.stepSize: 10
  }

  IntegerCfgSetting {
    dotPath: 'ui.page.maximumFlickVelocity'
    description: qsTr('Maximum page flick velocity (in pixels per second)')
    spin.from: 10
    spin.to: 100000
    spin.stepSize: 50
  }
  IntegerCfgSetting {
    dotPath: 'ui.page.downFlickPPS'
    description: qsTr('How much to flick when "down" is pressed (in pps)')
    spin.from: -1000
    spin.to: 0
    spin.stepSize: 50
  }
  IntegerCfgSetting {
    dotPath: 'ui.page.upFlickPPS'
    description: qsTr('How much to flick when "up" is pressed (in pps)')
    spin.from: 10
    spin.to: 100000
    spin.stepSize: 50
  }
  IntegerCfgSetting {
    dotPath: 'ui.page.pageDownFlickPPS'
    description: qsTr('How much to flick when "page down" is pressed (in pps)')
    spin.from: -1000
    spin.to: 0
    spin.stepSize: 50
  }
  IntegerCfgSetting {
    dotPath: 'ui.page.pageUpFlickPPS'
    description: qsTr('How much to flick when "page up" is pressed (in pps)')
    spin.from: 10
    spin.to: 100000
    spin.stepSize: 50
  }

  Text {
    text: qsTr('Fonts')
    font.bold: true
    font.pointSize: 20
  }

  IntegerCfgSetting {
    dotPath: 'ui.fonts.links.pointSize'
    description: qsTr('Font size for links')
    spin.from: 8
    spin.to: 42
    spin.stepSize: 2
  }

  IntegerCfgSetting {
    dotPath: 'ui.fonts.text.pointSize'
    description: qsTr('Font size for normal text')
    spin.from: 8
    spin.to: 42
    spin.stepSize: 2
  }

  IntegerCfgSetting {
    dotPath: 'ui.fonts.preformattedText.pointSize'
    description: qsTr('Font size for preformatted text')
    spin.from: 8
    spin.to: 42
    spin.stepSize: 2
  }
}
