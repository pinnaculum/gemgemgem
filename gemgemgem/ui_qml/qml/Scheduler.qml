import QtQuick 2.0

/* From: https://stackoverflow.com/a/69708612/12893835 */

Timer {
  id: timer

  property var _cbFunc: null
  property int _asyncTimeout: 250

  // Execute the callback asynchonously (ommiting a specific delay time)
  function async( cbFunc ) {
    delay( cbFunc, _asyncTimeout )
  }

  // Start the timer and execute the provided callback ONCE after X ms
  function delay( cbFunc, milliseconds ) {
    _start( cbFunc, milliseconds, false )
  }

  // Start the timer and execute the provided callback repeatedly every X ms
  function periodic( cbFunc, milliseconds ) {
    _start( cbFunc, milliseconds, true )
  }

  function _start( cbFunc, milliseconds, isRepeat ) {
    if( cbFunc === null ) return
    cancel()
    _cbFunc    = cbFunc
    timer.interval = milliseconds
    timer.repeat   = isRepeat
    timer.triggered.connect( cbFunc )
    timer.start()
  }

  // Stop the timer and unregister the cbFunc
  function cancel() {
    if( _cbFunc === null ) return
    timer.stop()
    timer.triggered.disconnect( _cbFunc )
    _cbFunc = null
  }
}
