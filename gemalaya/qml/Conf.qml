pragma Singleton
import QtQuick 2.2

QtObject {
  property var c: {
    return gemalaya.getConfig()
  }

  function changeTheme(name) {
    set('ui.theme', name)

    update()
  }

  property var themesNames: gemalaya.themesNames()

  property var theme: {
    let subTheme = c.ui.subTheme ? c.ui.subTheme : c.ui.theme

    return gemalaya.getThemeConfig(c.ui.theme)
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

  property var fontPrefs: {
    return c.ui.fonts
  }

  property var shortcuts: {
    return c.ui.shortcuts
  }

  property var stackShortcuts: {
    return c.ui.stackShortcuts
  }

  property var linksShortcuts: {
    return c.ui.linksShortcuts
  }

  property var textItemShortcuts: {
    return c.ui.textItemShortcuts
  }

  property var ui: c.ui

  function cfgForMimeType(mtype) {
    /* Find the configuration for a certain MIME type */
    for (let [mregex, cfg] of Object.entries(c.ui.mimeConfig)) {
      if (mtype.match(mregex)) {
        return cfg
      }
    }
    return null
  }

  function themeRsc(name) {
    return gemalaya.getThemeRscPath(c.ui.theme, name)
  }

  function update() {
    this.c = gemalaya.getConfig()
    this.theme = gemalaya.getThemeConfig(c.ui.theme)
  }

  function set(dotattr, value) {
    gemalaya.set(dotattr, value)
  }

  function get(dotattr) {
    return gemalaya.get(dotattr)
  }
}
