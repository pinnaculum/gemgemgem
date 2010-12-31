pragma Singleton
import QtQuick 2.2

QtObject {
  function animate(anims, control) {
    for (let name in anims) {
      let anim = anims[name]

      var component = Qt.createComponent(anim.component)

      let props = Object.assign({
        targetItem: control
      }, anim.properties)
      let item = component.createObject(control, props)

      item.running = true
    }
  }
}
