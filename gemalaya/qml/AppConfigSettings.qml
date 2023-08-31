import QtQuick 2.14
import QtQuick.Layouts 1.4

ColumnLayout {
  Text {
    text: qsTr('Timers')
    font.bold: true
    font.pointSize: 20
  }
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
    spin.to: 10000
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
    spin.to: 10000
    spin.stepSize: 50
  }
  IntegerCfgSetting {
    dotPath: 'ui.page.pageDownFlickPPS'
    description: qsTr('How much to flick when "page down" is pressed (in pps)')
    spin.from: -5000
    spin.to: 0
    spin.stepSize: 50
  }
  IntegerCfgSetting {
    dotPath: 'ui.page.pageUpFlickPPS'
    description: qsTr('How much to flick when "page up" is pressed (in pps)')
    spin.from: 10
    spin.to: 10000
    spin.stepSize: 50
  }
  IntegerCfgSetting {
    dotPath: 'ui.page.maxItemsPerPageSection'
    description: qsTr('Maximum items rendered per page section')
    spin.from: 32
    spin.to: 8192
    spin.stepSize: 16
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
    spin.stepSize: 1
  }

  IntegerCfgSetting {
    dotPath: 'ui.fonts.text.pointSize'
    description: qsTr('Font size for normal text')
    spin.from: 8
    spin.to: 42
    spin.stepSize: 1
  }

  IntegerCfgSetting {
    dotPath: 'ui.fonts.preformattedText.pointSize'
    description: qsTr('Font size for preformatted text')
    spin.from: 8
    spin.to: 42
    spin.stepSize: 1
  }
}
