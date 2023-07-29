pragma Singleton
import QtQuick 2.2

QtObject {
  property var c: {
    return gemalaya.getConfig()
  }


  property var gemspace: {
    return c.ui.gemspace
  }

  property var links: {
    return c.ui.links
  }

  property var shortcuts: {
    return c.ui.shortcuts
  }

  function set(dotattr, value) {
    return gemalaya.set(dotattr, value)
  }
}
