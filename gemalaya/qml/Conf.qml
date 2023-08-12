pragma Singleton
import QtQuick 2.2

QtObject {
  property var c: {
    return gemalaya.getConfig()
  }

  property var theme: {
    let activeTheme = c.ui.theme

    return c.themes[activeTheme]
  }

  property var gemspace: {
    return theme.gemspace
  }

  property var links: {
    return theme.links
  }

  property var text: {
    return theme.text
  }

  property var heading: {
    return theme.heading
  }

  property var shortcuts: {
    return c.ui.shortcuts
  }

  property var ui: c.ui

  function themeRsc(name) {
    return `qrc:/gemalaya/themes/${c.ui.theme}/${name}`
  }

  function set(dotattr, value) {
    return gemalaya.set(dotattr, value)
  }
}
