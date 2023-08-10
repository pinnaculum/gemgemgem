import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.4

import Gemalaya 1.0

ScrollView {
  id: sview

  property alias page: page
  property Item addrController

  property double bigStep: Conf.ui.page.stepBig

  Layout.fillWidth: true
  Layout.fillHeight: true

  signal urlChanged(url currentUrl)

  GeminiAgent {
    id: agent

    onSrvResponse: {
      let urlString = resp.url
      var urlObject = new URL(resp.url)

      var firstLink
      var prevLink
      var nextLink

      /* Clear the page */
      page.clear()

      if (resp.rsptype === 'input') {
        var component = Qt.createComponent('InputItem.qml')
        var item = component.createObject(sview.page, {
          sendUrl: urlString,
          promptText: resp.prompt,
          width: sview.width
        })
        item.sendRequest.connect(geminiSendInput)

        page.forceActiveFocus()
        urlChanged(urlObject)
        return
      }

      resp.model.forEach(function(gemItem) {
        var props
        var component
        var item

        switch(gemItem.type) {
          case 'link':
            var keysym
            var linkUrl

            component = Qt.createComponent('LinkItem.qml')

            props = {
              title: gemItem.title,
              baseUrl: urlString,
              href: gemItem.href,
              width: sview.width,
              keybAccessSeq: gemItem.keyseq,
              nextLinkItem: prevLink ? prevLink : null
            }

            if (component.status == Component.Ready) {
              item = component.createObject(sview.page, props)
              item.linkClicked.connect(geminiLinkClicked)

              if (prevLink) {
                prevLink.nextLinkItem = item
              }

              prevLink = item

              if (firstLink === undefined)
                firstLink = item
            }

            break

          case 'regular':
          case 'quote':
            var component = Qt.createComponent('TextItem.qml')
            props = {
              content: gemItem.title,
              width: sview.width * 0.95,
              nextLinkItem: prevLink ? prevLink : null,
              quote: gemItem.type === 'quote'
            }
            item = component.createObject(sview.page, props)
            if (prevLink) {
              prevLink.nextLinkItem = item
            }
            prevLink = item
            break

          default:
            break
        }
      })

      addrController.histAdd(urlString)

      urlChanged(urlObject)

      page.forceActiveFocus()

      if (firstLink) {
        firstLink.forceActiveFocus()
        firstLink.focus = true
      }

      vsbar.position = 0
    }
  }

  ScrollBar.vertical: ScrollBar {
    id: vsbar
    parent: sview
    x: sview.mirrored ? 0 : sview.width - width
    y: sview.topPadding
    height: sview.availableHeight
    policy: ScrollBar.AlwaysOn
    stepSize: Conf.ui.page.stepSmall
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

    try {
      urlObject = new URL(href)
    } catch(err) {
      return
    }

    var urlString = urlObject.toString()
    var result = agent.geminiModelize(urlString, null, {})
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

    property alias scrollView: sview

    property int currentFocusedIndex: -1

    function clear() {
      for (let i=0; i < children.length; i++) {
        children[i].destroy()
      }
      page.children = []
    }
  }
}
