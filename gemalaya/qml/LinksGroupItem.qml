import QtQuick 2.2
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.4

GridLayout {
  id: grid
  objectName: 'linksGroupItem'
  flow: GridLayout.LeftToRight
  layoutDirection: Qt.LeftToRight
  columns: Conf.ui.links.gridColumns
  rowSpacing: Conf.ui.links.gridRowSpacing
  clip: Conf.ui.links.gridLimitHeight
  opacity: collapsed ?
           Conf.ui.links.gridCollapsedOpacityPercentage / 100 : 1

  property bool collapsed: Conf.ui.links.gridLimitHeight && mHeight !== -1
  property real limitedHeight: Conf.ui.links.gridMaxCollapsedHeight
  property real mHeight: limitedHeight
  Layout.maximumHeight: Conf.ui.links.gridLimitHeight ? mHeight : -1

  signal linkClicked(string baseUrl, string href)

  /* Signal emitted when one of the links in the grid is focused/unfocused */
  signal linkFocused(bool focused)

  /* Skip the whole grid and focus the next thing in the page */
  signal skipGrid()

  function expand() {
    mHeight = limitedHeight
  }

  onFocusChanged: {
    /* If the links grid gets the focus, focus the first link in the grid */

    if (focus && children.length > 0)
      children[0].focus = true
  }

  onLinkFocused: {
    for (var idx=0; idx < children.length; idx++) {
      if (children[idx].focus) {
        mHeight = -1
        return
      }
    }
    mHeight = limitedHeight
  }

  onSkipGrid: {
    /* Get the last item in the grid and force the focus
     * on the next item in the layout */

     grid.children[grid.children.length - 1]
      .nextLinkItem.forceActiveFocus()
  }

  function keybSeqLookup(seq) {
    var item

    for (var i=0; i < children.length; i++) {
      item = children[i]

      if (item.keybAccessSeq === seq) {
        return item
      }
    }

    return null
  }
}
