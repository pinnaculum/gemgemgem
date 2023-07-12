import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.4

ScrollView {
  id: sview

  property alias page: page
  property Item addrController

  property double bigStep: 0.2

  Layout.fillWidth: true
  Layout.fillHeight: true

  signal urlChanged(url currentUrl)

  ScrollBar.vertical: ScrollBar {
    id: vsbar
    parent: sview
    x: sview.mirrored ? 0 : sview.width - width
    y: sview.topPadding
    height: sview.availableHeight
    policy: ScrollBar.AlwaysOn
  }

  function geminiLinkClicked(clickedUrl, baseUrl) {
    var lu = new URL(clickedUrl.toString())
    var noSchemes = ['http:', 'https:']

    if (noSchemes.includes(lu.protocol)) {
      console.log('Unsupported protocol: ' + lu.protocol)
    } else {
      sview.browse(clickedUrl.toString(), baseUrl)
    }
  }

  function geminiSendInput(sendUrl, value) {
    sview.browse(sendUrl, null)
  }

  function isLowerCase(str) {
    return str === str.toLowerCase() &&
           str !== str.toUpperCase();
  }

  function num2letter(number){
    let alpha = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
    return alpha.charAt(number % alpha.length)
  }

  function browse(href, baseUrlUnused) {
    var urlObject
    var linkNo = 0

    try {
      urlObject = new URL(href)
    } catch(err) {
      return
    }

    var urlString = urlObject.toString()
    var result = gem.geminiModelize(urlString, null, {})

    if (result === undefined)
      return

    /* Clear the page */
    page.clear()

    if (result.rsptype === 'input') {
      var component = Qt.createComponent('InputItem.qml')
      var item = component.createObject(sview.page, {
        sendUrl: urlString,
        promptText: result.prompt,
        width: sview.width
      })
      item.sendRequest.connect(geminiSendInput)

      page.forceActiveFocus()
      urlChanged(urlObject)
      return
    }

    result.model.forEach(function(gemItem) {
      var props
      var component
      var item

      switch(gemItem.type) {
        case 'link':
          var keysym
          var linkUrl

          component = Qt.createComponent('LinkItem.qml')

          if (linkNo <= 9) {
            keysym = linkNo
          } else {
            let n = linkNo - 10
            let ls = num2letter(n)

            if (isLowerCase(ls) && n < 52) {
              keysym = ls
            } else {
              if (n >= 52)
                keysym = 'Ctrl+' + ls
              else
                keysym = 'Shift+' + ls
            }
          }

          props = {
            title: gemItem.title,
            baseUrl: href,
            href: gemItem.href,
            width: sview.width,
            keybAccessSeq: keysym
          }

          if (component.status == Component.Ready) {
            item = component.createObject(sview.page, props)
            item.linkClicked.connect(geminiLinkClicked)

            linkNo += 1
          }

          break

        case 'regular':
        case 'quote':
          var component = Qt.createComponent('TextItem.qml')
          props = {
            content: gemItem.title,
            width: sview.width * 0.95,
            quote: gemItem.type === 'quote'
          }
          item = component.createObject(sview.page, props)
          break
          
        default:
          break
      }
    })

    addrController.histAdd(urlString)

    urlChanged(urlObject)

    page.forceActiveFocus()
    vsbar.position = 0
  }

  onUrlChanged: {
    addrController.url = currentUrl.toString()
  }

  Keys.onPressed: {
    /* Should convert those to Actions */
    if (event.key === Qt.Key_Home) {
      vsbar.position = 0
    }
    if (event.key === Qt.Key_End) {
      vsbar.position = 1.0 - vsbar.size
    }
    if (event.key === Qt.Key_PageDown) {
      if (vsbar.position < (1.0 - vsbar.size - bigStep))
        vsbar.position += bigStep
      else
        vsbar.position = 1.0 - vsbar.size
    }
    if (event.key === Qt.Key_PageUp) {
      if (vsbar.position > bigStep)
        vsbar.position -= bigStep
      else
        vsbar.position = 0
    }
  }

  ColumnLayout {
    anchors.fill: parent
    id: page
    Layout.maximumWidth: sview.width

    property int currentFocusedIndex: -1

    function clear() {
      for (let i=0; i < children.length; i++) {
        children[i].destroy()
      }
      page.children = []
    }
  }
}
