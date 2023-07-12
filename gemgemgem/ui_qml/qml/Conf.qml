pragma Singleton
import QtQuick 2.2

QtObject {
  property var cfg: {
    return gemalaya.getConfig()
  }

  function set(dotattr, value) {
    return gemalaya.set(dotattr, value)
  }
}
