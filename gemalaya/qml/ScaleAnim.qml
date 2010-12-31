import QtQuick 2.2

SequentialAnimation {
  id: anim
  property Item targetItem
  property double scale: 1.5
  property int duration: 300
  property int pause: 100

  ScaleAnimator {
    target: targetItem
    from: 1
    to: scale
    duration: anim.duration * 0.5
  }
  PauseAnimation {
    duration: anim.pause
  }
  ScaleAnimator {
    target: targetItem
    to: 1
    duration: anim.duration * 0.5
  }
}
