import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.4

import Gemalaya 1.0

ScrollView {
  id: sview

  property alias page: page
  property Item addrController

  property double bigStep: Conf.ui.page.stepBig

  property string linkSeqInput

  Layout.fillWidth: true
  Layout.fillHeight: true

  signal urlChanged(url currentUrl)
  signal linkActivated(url linkUrl, url baseUrl)

  Scheduler {
    id: sched
  }

  GeminiAgent {
    id: agent

    onSrvError: pageError(message)

    onSrvResponse: {
      let urlString = resp.url
      var urlObject = new URL(resp.url)

      var linkNum = 0
      var firstLink
      var prevLink
      var nextLink

      /* Clear the page */
      page.clear()

      urlChanged(urlObject)

      if (resp.rsptype === 'input') {
        var component = Qt.createComponent('InputItem.qml')
        var item = component.createObject(sview.page, {
          pageLayout: page,
          sendUrl: urlString,
          promptText: resp.prompt
        })
        item.sendRequest.connect(geminiSendInput)
        item.focusInput()

        pageOaRestore.running = true
        addrController.histAdd(urlString)
        return
      } else if (resp.rsptype === 'redirect') {
        let rurl = new URL(resp.redirectUrl)

        sview.browse(rurl.toString(), null)
        return
      } else if (resp.rsptype === 'error' || resp.rsptype === 'failure') {
        sview.pageError('Error: ' + resp.message)
        pageOaRestore.running = true
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
              pageLayout: page,
              title: gemItem.title,
              baseUrl: urlString,
              href: gemItem.href,
              width: sview.width,
              keybAccessSeq: linkNum,
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

              linkNum += 1
            }

            break

          case 'regular':
          case 'quote':
          case 'preformatted':
          case 'listitem':
            var component = Qt.createComponent('TextItem.qml')
            props = {
              content: gemItem.text,
              width: sview.width * 0.95,
              nextLinkItem: prevLink ? prevLink : null,
              textType: gemItem.type,
              quote: gemItem.type === 'quote'
            }
            item = component.createObject(sview.page, props)
            if (prevLink) {
              prevLink.nextLinkItem = item
            }
            prevLink = item
            break

          case 'heading':
            var component = Qt.createComponent('HeadingItem.qml')
            item = component.createObject(sview.page, {
              content: gemItem.text,
              hsize: gemItem.hsize,
              width: sview.width * 0.95
            })
            break

          default:
            break
        }
      })

      addrController.histAdd(urlString)

      sview.forceActiveFocus()

      if (firstLink) {
        firstLink.focus = true
      }

      vsbar.position = 0
      pageOaRestore.running = true
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

  function geminiLinkClicked(clickedUrlString, baseUrl) {
    var clickedUrl = new URL(clickedUrlString)
    var unsSchemes = ['http:', 'https:']

    if (unsSchemes.includes(clickedUrl.protocol)) {
      if (Conf.ui.openUnsupportedUrls == true)
        gemalaya.browserOpenUrl(clickedUrl.toString())
      else
        console.log('Unsupported protocol: ' + clickedUrl.protocol)
    } else {
      linkActivated(clickedUrl, baseUrl)
    }
  }

  function geminiSendInput(sendUrl, value) {
    sview.browse(sendUrl, null)
  }

  function isLowerCase(str) {
    return str === str.toLowerCase() &&
           str !== str.toUpperCase();
  }

  function browse(href, baseUrlUnused) {
    var urlObject

    try {
      urlObject = new URL(href)
    } catch(err) {
      return
    }

    agent.geminiModelize(urlObject.toString(), null, {})
  }

  function pageError(err) {
    page.clear()

    let component = Qt.createComponent('ErrorItem.qml')
    component.createObject(sview.page, {
      message: err
    })
  }

  onUrlChanged: {
    addrController.url = currentUrl.toString()
  }

  Keys.onPressed: {
    let numk = [
      Qt.Key_0,
      Qt.Key_1,
      Qt.Key_2,
      Qt.Key_3,
      Qt.Key_4,
      Qt.Key_5,
      Qt.Key_6,
      Qt.Key_7,
      Qt.Key_8,
      Qt.Key_9
    ]

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

    if (event.modifiers & Qt.ControlModifier) {
      linkSeqInput = ''
    }

    if (numk.includes(event.key) && linkSeqInput.length < 8) {
      linkSeqInput = linkSeqInput + event.text
    }

    sched.delay(function() {
      if (linkSeqInput.length > 0) {
        page.focusLinkForSequence(linkSeqInput)
      } else {
        linkSeqInput = ''
      }
    }, Conf.ui.keybSeqTimeout)
  }

  OpacityAnimator {
    id: pageOaRestore
    target: page
    from: 0.2
    to: 1
    duration: 1000
  }
  OpacityAnimator {
    id: pageOaDim
    target: page
    from: 1
    to: 0.2
    duration: 10
  }

  ColumnLayout {
    anchors.fill: parent
    id: page
    Layout.maximumWidth: sview.width

    property alias scrollView: sview
    property bool empty: children.length == 0

    function clear() {
      pageOaDim.running = true

      for(var i = children.length; i > 0 ; i--) {
        children[i-1].destroy()
      }

      page.children = []
    }

    function focusLinkForSequence(seq) {
      for (var i=0; i < children.length; i++) {
        let item = children[i]

        if (item.keybAccessSeq == seq) {
          linkSeqInput = ''
          item.focus = true
          item.linkAction.trigger()
        }
      }
      linkSeqInput = ''
    }
  }
}
