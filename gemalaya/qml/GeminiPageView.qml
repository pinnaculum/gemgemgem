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

  property string pageTitle
  property string linkSeqInput

  /* String containing the text we want to search in the page */
  property string searchTextInput
  property int searchTextItemIdx: 0

  /* Mode */
  property int actionMode: 0

  /* Page's alphanumerical link words */
  property var alphaLinksWords: []

  property var modes: Object.freeze({
    DEFAULT: 0,
    SEARCH: 1
  })

  property var currentResponse
  property int lastLinkNum: 0
  property int lastProcItemIdx: 0
  property var lastSectionItem: null

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
  signal fileDownloaded(url fileUrl, string filePath)
  signal keybSequenceMatch()
  signal textFound()

  Scheduler {
    /* main scheduler */
    id: sched
  }

  Scheduler {
    /* scrollbar's scheduler */
    id: sbsched
  }

  Scheduler {
    /* page section scheduler */
    id: pssched
  }

  GeminiAgent {
    id: agent

    onSrvError: {
      addrController.loading = false
      pageError(message)
    }

    onSrvResponse: {
      var urlString = resp.url
      var urlObject = new URL(resp.url)

      var linkNum = 0
      var itemNum = 0

      lastLinkNum = 0

      /* Clear the page */
      page.clear()
      addrController.loading = false

      urlChanged(urlObject)
      flickable.forceActiveFocus()

      if (resp.rsptype === 'input') {
        var component = Qt.createComponent('InputItem.qml')
        var item = component.createObject(flickable.page, {
          pageLayout: page,
          sendUrl: urlString,
          promptText: resp.prompt,
          words: alphaLinksWords,
          width: flickable.width - vsbar.width
        })
        item.sendRequest.connect(geminiSendInput)
        item.focusInput()

        pageOaRestore.running = true
        addrController.histAdd(urlString)
        alphaLinksWords = []
        return
      } else if (resp.rsptype === 'redirect') {
        let rurl = new URL(resp.redirectUrl)

        flickable.browse(rurl.toString(), null)
        return
      } else if (resp.rsptype === 'error' || resp.rsptype === 'failure') {
        flickable.pageError('Error: ' + resp.message)
        pageOaRestore.running = true
        addrController.histAdd(urlString)
        return
      } else if (resp.rsptype === 'raw') {
        displayRawFile(resp)
        pageOaRestore.running = true
        return
      }

      renderGemTextResponse(resp, 0)

      if (resp.title) {
        pageTitle = resp.title
      }

      addrController.histAdd(urlString)

      vsbar.position = 0
      pageOaRestore.running = true
    }
  }

  ScrollBar.vertical: ScrollBar {
    id: vsbar
    parent: flickable
    x: flickable.width - width
    height: flickable.contentHeight
    width: Conf.theme.scrollBar.width
    policy: ScrollBar.AlwaysOn

    property bool moving: false
    property double prevPos: 0
    property double scrollSpeed: 0

    contentItem: Rectangle {
      id: scrollBarContent
      property color movingColor: Conf.theme.scrollBar.moving.barColor
      radius: 15
      color: moving ? Conf.theme.scrollBar.moving.barColor :
        Conf.theme.scrollBar.barColor
    }
    background: Rectangle {
      id: scrollBarBg
      property color movingColor: Conf.theme.scrollBar.moving.bgColor

      /* accentuate the red component a little when we're scrolling */
      color: moving ? Qt.rgba(
        movingColor.r + vsbar.scrollSpeed,
        movingColor.g - vsbar.scrollSpeed,
        movingColor.b - vsbar.scrollSpeed,
        movingColor.a
      ) : Conf.theme.scrollBar.bgColor

      border.color: moving ? Conf.theme.scrollBar.moving.bgBorderColor :
          Conf.theme.scrollBar.bgBorderColor
      border.width: moving ? 1 : 0
      radius: moving ? 15 : 0
    }

    SequentialAnimation {
      id: sbanim

      PropertyAnimation {
        target: scrollBarBg
        property: "color"
        from: scrollBarBg.color
        to: Qt.rgba(
          scrollBarBg.color.r + vsbar.scrollSpeed,
          scrollBarBg.color.g - vsbar.scrollSpeed,
          scrollBarBg.color.b - vsbar.scrollSpeed,
          scrollBarBg.color.a
        )
        duration: 10
      }
    }

    onPositionChanged: {
      let diff = position > prevPos ? position - prevPos : prevPos - position
      scrollSpeed = diff * 75

      prevPos = position

      sbsched.cancel()
      moving = true

      sbsched.delay(function() {
        moving = false
      }, 200)
    }
  }

  function geminiLinkClicked(clickedUrlString, baseUrl) {
    linkActivated(new URL(clickedUrlString), baseUrl)
  }

  function geminiSendInput(sendUrl, value) {
    flickable.browse(sendUrl, null)
  }

  function isLowerCase(str) {
    return str === str.toLowerCase() &&
           str !== str.toUpperCase();
  }

  function displayRawFile(resp) {
    switch(true) {
      case /^text\/plain/i.test(resp.contentType):
        Qt.createComponent('TextItem.qml').createObject(
          flickable.page, {
            content: resp.data,
            width: flickable.width,
            textType: 'regular'
          }
        )
        break

      case /^(video|audio)\/.*/i.test(resp.contentType):
        Qt.createComponent('MPlayer.qml').createObject(
          flickable.page, {
            source: resp.downloadPath,
            desiredVideoHeight: flickable.height,
            width: flickable.width
          }
        )
        break

      default:
        pageError('Unsupported content type: ' + resp.contentType)

        let item = Qt.createComponent('FileDownloadItem.qml').createObject(
          flickable.page, {
            width: flickable.width,
            contentType: resp.contentType,
            fileUrl: resp.url,
            filePath: resp.downloadPath
        })
        item.openButton.forceActiveFocus()

        fileDownloaded(resp.url, resp.downloadPath)
        break
    }
  }

  function computeUrl(href, base) {
    try {
      var hrefu = new URL(href)

      if (hrefu && Conf.supportedProtocols.includes(hrefu.protocol)) {
        return hrefu
      }
    } catch(err) {
      return new URL(gem.buildUrl(href, base))
    }
  }

  function renderGemTextResponse(resp, startItemIdx) {
    var urlString = resp.url
    var urlObject = new URL(resp.url)

    var linkNum = lastLinkNum > 0 ? lastLinkNum : 0
    var itemNum = 0

    var firstLink
    var firstItem
    var prevLink = lastSectionItem ? lastSectionItem : null
    var nextLink

    if (startItemIdx >= (resp.model.length - 1)) {
      console.log('Already rendered it all')
      return
    }

    for (var gemItem of resp.model.slice(startItemIdx, -1)) {
      var props
      var component
      var item

      switch(gemItem.type) {
        case 'blank':
          Qt.createComponent('BlankItem.qml').createObject(
            flickable.page, {}
          )
          break

        case 'link':
          var keysym
          var linkUrl = computeUrl(gemItem.href, urlString)

          component = Qt.createComponent('LinkItem.qml')

          /* Store words from links to be reused in input responses */
          if (gemItem.alphan != null && !alphaLinksWords.includes(gemItem.alphan))
            alphaLinksWords.push(gemItem.alphan)

          props = {
            pageLayout: page,
            title: gemItem.title,
            linkUrl: linkUrl,
            baseUrl: urlString,
            href: gemItem.href,
            width: flickable.width,
            flickable: flickable,
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
            lastSectionItem = item

            if (firstLink === undefined)
              firstLink = item

            if (firstItem === undefined)
              firstItem = item

            linkNum += 1
          }

          break

        case 'linksgroup':
          var lgLayout = Qt.createComponent('LinksGroupItem.qml').createObject(
            flickable.page, {}
          )

          gemItem.links.forEach(function(link) {
            var litem
            var linkUrl = computeUrl(link.href, urlString)

            litem = Qt.createComponent('LinkButton.qml').createObject(lgLayout, {
              title: link.title,
              linkUrl: linkUrl,
              baseUrl:urlString,
              href: link.href,
              nextLinkItem: prevLink ? prevLink : null,
              keybAccessSeq: linkNum
            })
            litem.linkClicked.connect(geminiLinkClicked)

            if (prevLink)
              prevLink.nextLinkItem = litem

            prevLink = litem

            linkNum += 1

            if (firstLink === undefined)
              firstLink = litem

            if (firstItem === undefined)
              firstItem = litem
          })

          break

        case 'regular':
        case 'quote':
        case 'preformatted':
        case 'listitem':
          if (gemItem.text.length == 0)
            break

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
          if (firstItem === undefined)
            firstItem = item
          prevLink = item
          lastSectionItem = item
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

      lastProcItemIdx = startItemIdx + itemNum
      itemNum += 1

      if (itemNum > Conf.ui.page.maxItemsPerPageSection) {
        /* Maximum number of page items reached, store the response
         * and get out of here */
        currentResponse = resp
        break
      }
    }

    /* Remember the number/index of the last link */
    lastLinkNum = linkNum

    if (firstItem && startItemIdx == 0) {
      firstItem.focus = true
    }
  }

  function reset() {
    /* Reset */
    pageTitle = ""
    searchTextInput = ""
    actionMode = modes.DEFAULT
    lastLinkNum = 0
    lastProcItemIdx = 0
  }

  function titanUpload(titanUrl, filePath) {
    /* Upload a file with the titan protocol */

    reset()

    addrController.loading = true

    var result = agent.geminiModelize(titanUrl.toString(), null, {
      titanUploadPath: filePath,
      linksMode: Conf.ui.links.layoutMode
    })
  }

  function browse(href, baseUrlUnused) {
    var urlObject

    try {
      urlObject = new URL(href)
    } catch(err) {
      pageError('Invalid URL')
      return
    }

    reset()

    agent.geminiModelize(urlObject.toString(), null, {
      downloadsPath: Conf.c.downloadsPath,
      linksMode: Conf.ui.links.layoutMode
    })

    addrController.loading = true
  }

  function pageError(err) {
    page.clear()

    Qt.createComponent('ErrorItem.qml').createObject(flickable.page, {
      message: err
    })
  }

  function renderNextPageSection() {
    renderGemTextResponse(currentResponse, lastProcItemIdx + 1)
  }

  onUrlChanged: {
    addrController.url = currentUrl.toString()
  }

  onContentYChanged: {
    pssched.cancel()

    if ((contentY + height) >= contentHeight &&
        currentResponse != undefined) {
      /* Reached the end of the flickable: render the rest of the page if
       * it hasn't been fully rendered yet */
      pssched.delay(function() {
        renderNextPageSection()
      }, 200)
    }
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

    /* Text search mode */
    if (actionMode == modes.SEARCH) {
      if (event.key === Qt.Key_Escape) {
        /* Escape pressed: go back to the default mode */
        actionMode = modes.DEFAULT
        searchTextInput = ""
      } else if (event.key == Qt.Key_Backspace) {
        if (searchTextInput.length > 0)
          searchTextInput = searchTextInput.slice(0, -1)
      } else if (event.text.match(/[\w\s_\.]/)) {
        /* Allowed search character: append and schedule a search */
        sched.cancel()
        searchTextInput += event.text

        sched.delay(function() {
          page.searchText(searchTextInput)
        }, 700)
      }

      event.accepted = true
      return
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
    width: flickable.width - (vsbar.width * 2)

    property alias scrollView: flickable
    property bool empty: children.length == 0

    function clear() {
      for(var i = children.length; i > 0 ; i--) {
        try {
          children[i-1].destroy()
        } catch(error) {
          console.log('Failed to destroy: ' + children[i-1])
          continue
        }
      }

      page.children = []
      pageTitle = ""
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
          children[i+1].focus = true
          return
        }
      }
    }

    function itemVisible(item) {
      /* Returns true if this item is in the visible part of the flickable */
      return (item.y < (flickable.contentY + flickable.height) &&
              item.y > flickable.contentY)
    }

    function focusFirstVisibleItem() {
      /* Focus the first visible item in the page. Only focus text or link
       * items, because these are linked in the "Tab" navigation system */

      for (var i=0; i < children.length; i++) {
        let item = children[i]

        if (itemVisible(item) &&
           (item.objectName.startsWith('linkItem') ||
            item.objectName.startsWith('linksGroupItem') ||
            item.objectName.startsWith('textItem'))) {
          item.focus = true
          break
        }
      }
    }

    function focusLinkForSequence(seq) {
      var item
      var subitem
      var itemypos

      for (var i=0; i < children.length; i++) {
        item = children[i]
        itemypos = item.y

        if (item.hasOwnProperty('keybSeqLookup')) {
          /* This is a links group item (grid). Check if a link in the
           * group matches the keyboard sequence */

          subitem = item.keybSeqLookup(seq)

          if (subitem !== null) {
            itemypos = item.y + subitem.y
            item = subitem
          }
        }

        if (item.keybAccessSeq === seq) {
          linkSeqInput = ''
          item.focus = true

          if (itemypos > (flickable.contentY + flickable.height) ||
              itemypos < flickable.contentY) {
            /* The link isn't visible to the user: scroll the flickable to its
             * position in the page but don't activate it (it's unlikely that
             * you'd want to open a link that's outside of the page's scope
             * just based on its number) */
            flickable.contentY = itemypos - (flickable.height / 8)
          } else {
            /* The link is visible, just open it */

            keybSequenceMatch()

            item.linkAction.trigger()
          }
        }
      }
      linkSeqInput = ''
    }

    function searchText(text) {
      let start = searchTextItemIdx > 0 ? searchTextItemIdx + 1 : 0

      for (var i=start; i < children.length; i++) {
        let item = children[i]

        try {
          if (item.searchText(text)) {
            item.focus = true
            flickable.contentY = item.y - (flickable.height / 8)
            searchTextItemIdx = i

            textFound()
            return
          }
        } catch(e) {
          continue
        }
      }

      /* reset idx */
      searchTextItemIdx = 0
    }
  }
}
