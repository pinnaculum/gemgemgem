import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.4

import Gemalaya 1.0

Flickable {
  id: flickable

  clip: true
  flickDeceleration: Conf.ui.page.flickDeceleration
  flickableDirection: Flickable.VerticalFlick
  maximumFlickVelocity: Conf.ui.page.maximumFlickVelocity

  property alias page: page
  property Item addrController

  property string linkSeqInput

  Layout.fillWidth: true
  Layout.fillHeight: true

  contentHeight: page.height

  rebound: Transition {
    NumberAnimation {
      properties: "x,y"
      duration: 1200
      easing.type: Easing.OutBounce
    }
  }

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
        var item = component.createObject(flickable.page, {
          pageLayout: page,
          sendUrl: urlString,
          promptText: resp.prompt,
          width: flickable.width
        })
        item.sendRequest.connect(geminiSendInput)
        item.focusInput()

        pageOaRestore.running = true
        addrController.histAdd(urlString)
        return
      } else if (resp.rsptype === 'redirect') {
        let rurl = new URL(resp.redirectUrl)

        flickable.browse(rurl.toString(), null)
        return
      } else if (resp.rsptype === 'error' || resp.rsptype === 'failure') {
        flickable.pageError('Error: ' + resp.message)
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

            if (gemItem.href.startsWith('http://') ||
                gemItem.href.startsWith('https://'))
              linkUrl = new URL(gemItem.href)
            else
              linkUrl = new URL(gem.buildUrl(gemItem.href, urlString))

            component = Qt.createComponent('LinkItem.qml')

            props = {
              pageLayout: page,
              title: gemItem.title,
              linkUrl: linkUrl,
              baseUrl: urlString,
              href: gemItem.href,
              width: flickable.width,
              keybAccessSeq: linkNum,
              nextLinkItem: prevLink ? prevLink : null
            }

            if (component.status == Component.Ready) {
              item = component.createObject(flickable.page, props)
              item.linkClicked.connect(geminiLinkClicked)
              item.setup()

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
              width: flickable.width * 0.95,
              nextLinkItem: prevLink ? prevLink : null,
              textType: gemItem.type,
              quote: gemItem.type === 'quote'
            }
            item = component.createObject(flickable.page, props)
            if (prevLink) {
              prevLink.nextLinkItem = item
            }
            prevLink = item
            break

          case 'heading':
            var component = Qt.createComponent('HeadingItem.qml')
            item = component.createObject(flickable.page, {
              content: gemItem.text,
              hsize: gemItem.hsize,
              width: flickable.width * 0.95
            })
            break

          default:
            break
        }
      })

      addrController.histAdd(urlString)

      flickable.forceActiveFocus()

      if (firstLink) {
        firstLink.focus = true
      }

      vsbar.position = 0
      pageOaRestore.running = true
    }
  }

  ScrollBar.vertical: ScrollBar {
    id: vsbar
    parent: flickable
    x: flickable.width - width
    height: flickable.contentHeight
    width: 15
    policy: ScrollBar.AlwaysOn
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
    flickable.browse(sendUrl, null)
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
    component.createObject(flickable.page, {
      message: err
    })
  }

  onUrlChanged: {
    addrController.url = currentUrl.toString()
  }

  Keys.onPressed: {
    let flickMultiplier = 1
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

    if (event.modifiers & Qt.ShiftModifier)
      flickMultiplier *= 2

    if (event.modifiers & Qt.ControlModifier) {
      flickMultiplier *= 2
      linkSeqInput = ''

      if (event.key === Qt.Key_Right) {
        page.focusNextElement()
      }

      if (event.key === Qt.Key_Left) {
        page.focusPreviousElement()
      }
    }

    /* Should convert those to Actions */
    if (event.key === Qt.Key_Home) {
      /* Go to the top and flick it, this will trigger a rebound */
      vsbar.position = 0

      flickable.flick(0, Conf.ui.page.upFlickPPS)
    }
    if (event.key === Qt.Key_End) {
      /* Go to the bottom and flick it, this will trigger a rebound */
      vsbar.position = 1.0 - vsbar.size

      flickable.flick(0, Conf.ui.page.downFlickPPS)
    }
    if (event.key === Qt.Key_Down) {
     flickable.flick(0, Conf.ui.page.downFlickPPS * flickMultiplier)
    }
    if (event.key === Qt.Key_Up) {
     flickable.flick(0, Conf.ui.page.upFlickPPS * flickMultiplier)
    }
    if (event.key === Qt.Key_PageDown) {
     flickable.flick(0, Conf.ui.page.pageDownFlickPPS * flickMultiplier)
    }
    if (event.key === Qt.Key_PageUp) {
      flickable.flick(0, Conf.ui.page.pageUpFlickPPS * flickMultiplier)
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

    event.accepted = true
  }

  OpacityAnimator {
    id: pageOaRestore
    target: page
    from: 0.1
    to: 1
    duration: 500
  }
  OpacityAnimator {
    id: pageOaDim
    target: page
    from: 1
    to: 0.1
    duration: 10
  }

  ColumnLayout {
    id: page
    Layout.maximumWidth: flickable.width

    property alias scrollView: flickable
    property bool empty: children.length == 0

    function clear() {
      pageOaDim.running = true

      for(var i = children.length; i > 0 ; i--) {
        children[i-1].destroy()
      }

      page.children = []
    }

    function delayScrollTo(pos){
      if (Conf.ui.page.scrollToItemOnFocus == true) {
        sched.delay(function() {
          instantScrollTo(pos)
        }, 800)
      } else {
        sched.cancel()
      }
    }

    function instantScrollTo(ypos) {
      var posm = (flickable.height + flickable.contentY) - 128

      if (ypos > posm) {
        flickable.contentY = ypos - (flickable.height / 8)
      }
    }

    function focusPreviousElement() {
      for (var i=0; i < children.length; i++) {
        let item = children[i]
        if (item.activeFocus == true && i > 0) {
          item.focus = false
          children[i-1].focus = true
          return
        }
      }
    }

    function focusNextElement() {
      for (var i=0; i < children.length; i++) {
        let item = children[i]
        if (item.activeFocus == true) {
          item.focus = false
          console.log(item + 'had the focus')
          children[i+1].focus = true
          return
        }
      }
    }

    function itemVisible(item) {
      return (item.y < (flickable.contentY + flickable.height) ||
              item.y > flickable.contentY)
    }

    function focusLinkForSequence(seq) {
      for (var i=0; i < children.length; i++) {
        let item = children[i]

        if (item.keybAccessSeq == seq) {
          var posm = (flickable.height + item.y) - 128

          linkSeqInput = ''
          item.focus = true

          if (item.y > (flickable.contentY + flickable.height) ||
              item.y < flickable.contentY) {
            /* The link isn't visible to the user: scroll the flickable to its
             * position in the page but don't activate it (it's unlikely that
             * you'd want to open a link that's outside of the page's scope
             * just based on its number) */
            flickable.contentY = item.y - (flickable.height / 8)
          } else {
            /* The link is visible, just open it */
            item.linkAction.trigger()
          }
        }
      }
      linkSeqInput = ''
    }
  }
}
