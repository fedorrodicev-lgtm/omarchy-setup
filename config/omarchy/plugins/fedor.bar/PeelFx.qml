import QtQuick
import QtQuick.Effects

// Liquid-drop motion for a bar dropdown (a KeyboardPanel from qs.Ui).
//
// KeyboardPanel lives in /usr/share and only fades its card, so the bar hangs
// this onto the card from outside. On open a small drop forms under the icon,
// hanging from the bar on a liquid neck; it falls and spreads into the full
// card (a mask reveals the card, so its content is never stretched), the neck
// pinches off, and the card squashes and settles. Closing pulls the card back
// into a drop under the icon while the stock 140ms fade runs.
Item {
  id: fx

  required property var win
  required property Item card

  readonly property string pos: win && win.barPos ? win.barPos : "top"
  readonly property bool horizontal: pos === "top" || pos === "bottom"

  // 0 = a drop under the icon; 1 = the whole card.
  property real reveal: 1
  // Squash-and-stretch after landing: >0 stretched along the drop, <0 squashed.
  property real stretch: 0
  // Neck thickness multiplier; 0 hides it.
  property real neck: 0

  // The icon's centre in card coordinates, so the drop forms right under it.
  readonly property real pivotX: {
    if (!win || !card) return 0
    var x = win.anchorScreenPos.x + win.anchorW / 2 - card.x
    return Math.max(0, Math.min(card.width, x))
  }
  readonly property real pivotY: {
    if (!win || !card) return 0
    var y = win.anchorScreenPos.y + win.anchorH / 2 - card.y
    return Math.max(0, Math.min(card.height, y))
  }
  readonly property real dropSize: {
    var icon = win ? Math.min(win.anchorW || 0, win.anchorH || 0) : 0
    return Math.max(16, Math.min(30, icon || 24))
  }

  function easeOut(t, power) {
    t = Math.max(0, Math.min(1, t))
    return 1 - Math.pow(1 - t, power)
  }
  function lerp(a, b, t) { return a + (b - a) * t }

  // The drop falls first (length leads), then spreads sideways.
  readonly property real alongT: easeOut(reveal * 1.4, 3)
  readonly property real acrossT: easeOut((reveal - 0.22) / 0.78, 3)

  // Drop rectangle in card coordinates.
  readonly property rect dropRect: {
    if (!card) return Qt.rect(0, 0, 0, 0)
    var d = dropSize, w = card.width, h = card.height
    // The drop swells a little as it falls, so it reads as a drop, not a stick.
    var fat = d * (1 + 0.6 * alongT)
    if (horizontal) {
      var dw = lerp(fat, w, acrossT), dh = lerp(d, h, alongT)
      var dx = lerp(pivotX - fat / 2, 0, acrossT)
      var dy = pos === "top" ? 0 : h - dh
      return Qt.rect(dx, dy, dw, dh)
    }
    var vw = lerp(d, w, alongT), vh = lerp(fat, h, acrossT)
    var vy = lerp(pivotY - fat / 2, 0, acrossT)
    var vx = pos === "left" ? 0 : w - vw
    return Qt.rect(vx, vy, vw, vh)
  }

  Scale {
    id: wobble
    origin.x: fx.horizontal ? fx.pivotX : (fx.pos === "left" ? 0 : fx.card.width)
    origin.y: fx.horizontal ? (fx.pos === "top" ? 0 : fx.card.height) : fx.pivotY
    xScale: fx.horizontal ? 1 - fx.stretch * 0.025 : 1 + fx.stretch * 0.045
    yScale: fx.horizontal ? 1 + fx.stretch * 0.045 : 1 - fx.stretch * 0.025
  }

  // Mask source: the drop shape, rendered offscreen in the panel's window.
  Item {
    id: dropMask
    width: fx.card ? fx.card.width : 0
    height: fx.card ? fx.card.height : 0
    visible: false
    layer.enabled: true

    Rectangle {
      x: fx.dropRect.x
      y: fx.dropRect.y
      width: fx.dropRect.width
      height: fx.dropRect.height
      radius: Math.min(width, height) / 2 * (1 - fx.acrossT) + Math.min(fx.card ? fx.card.radius : 0, Math.min(width, height) / 2) * fx.acrossT
      antialiasing: true
    }
  }

  Component {
    id: maskEffect
    MultiEffect {
      maskEnabled: true
      maskSource: dropMask
      maskThresholdMin: 0.35
      maskSpreadAtMin: 0.3
    }
  }

  // The liquid bridge from the bar edge down to the drop, flared at the bar
  // like a meniscus and pinched at the waist. Top/bottom bars only.
  Canvas {
    id: neckCanvas
    readonly property real thick: fx.dropSize * 0.75 * fx.neck
    readonly property real cx: fx.card ? fx.card.x + fx.pivotX : 0
    // Bar edge and the point inside the drop where the neck merges.
    readonly property real barEdge: fx.card && fx.win ? (fx.pos === "top" ? fx.card.y - fx.win.gap : fx.card.y + fx.card.height + fx.win.gap) : 0
    readonly property real dropEdge: fx.card ? (fx.pos === "top" ? fx.card.y + fx.dropSize * 0.5 : fx.card.y + fx.card.height - fx.dropSize * 0.5) : 0
    readonly property real span: Math.abs(dropEdge - barEdge)
    visible: fx.horizontal && thick > 0.5
    opacity: fx.card ? fx.card.opacity : 0
    x: cx - fx.dropSize
    y: Math.min(barEdge, dropEdge) - 3
    width: fx.dropSize * 2
    height: span + 6
    z: -1

    onThickChanged: requestPaint()
    onSpanChanged: requestPaint()

    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()
      if (thick <= 0.5) return
      var c = width / 2
      var top = 3, bottom = height - 3
      var flare = thick * 1.5, waist = thick * 0.45, base = thick
      // Flare sits on the bar side, the base inside the drop.
      var y0 = fx.pos === "top" ? top - 3 : bottom + 3
      var y1 = fx.pos === "top" ? bottom : top
      var a = y0 + (y1 - y0) * 0.35, b = y0 + (y1 - y0) * 0.7
      ctx.fillStyle = fx.card.color
      ctx.beginPath()
      ctx.moveTo(c - flare / 2, y0)
      ctx.bezierCurveTo(c - waist / 2, a, c - waist / 2, b, c - base / 2, y1)
      ctx.lineTo(c + base / 2, y1)
      ctx.bezierCurveTo(c + waist / 2, b, c + waist / 2, a, c + flare / 2, y0)
      ctx.closePath()
      ctx.fill()
    }
  }

  function attach() {
    dropMask.parent = card.parent
    neckCanvas.parent = card.parent
    card.transform = [wobble]
    card.layer.effect = maskEffect
  }

  function settle() {
    card.layer.enabled = false
    reveal = 1
    stretch = 0
    neck = 0
  }

  function playOpen() {
    closeAnim.stop()
    // Hopping between neighbouring icons gets a quicker drop without a neck.
    var switching = !!(win && win.popoutSwitching)
    reveal = 0
    stretch = 0
    neck = switching ? 0 : 1
    card.layer.enabled = true
    openAnim.duration = switching ? 360 : 620
    openAnim.restart()
    wobbleAnim.restart()
    if (!switching) neckAnim.restart()
  }

  function playClose() {
    openAnim.stop()
    wobbleAnim.stop()
    neckAnim.stop()
    neck = 0
    stretch = 0
    if (win && (win.popoutSwitchClosing || !win.visible)) {
      settle()
      return
    }
    card.layer.enabled = true
    closeAnim.restart()
  }

  NumberAnimation {
    id: openAnim
    target: fx; property: "reveal"; from: 0; to: 1
    duration: 520; easing.type: Easing.Linear
    onFinished: if (fx.win && fx.win.open) fx.settle()
  }

  NumberAnimation {
    id: neckAnim
    target: fx; property: "neck"; from: 1; to: 0
    duration: 360; easing.type: Easing.InQuad
  }

  SequentialAnimation {
    id: wobbleAnim
    NumberAnimation { target: fx; property: "stretch"; to: 1; duration: 140; easing.type: Easing.OutQuad }
    NumberAnimation { target: fx; property: "stretch"; to: -0.55; duration: 190; easing.type: Easing.InOutQuad }
    NumberAnimation { target: fx; property: "stretch"; to: 0.2; duration: 170; easing.type: Easing.InOutQuad }
    NumberAnimation { target: fx; property: "stretch"; to: 0; duration: 180; easing.type: Easing.OutQuad }
  }

  NumberAnimation {
    id: closeAnim
    target: fx; property: "reveal"; to: 0
    duration: 170; easing.type: Easing.InCubic
    onFinished: fx.settle()
  }

  Connections {
    target: fx.win
    ignoreUnknownSignals: true
    function onOpenChanged() {
      if (fx.win.open) fx.playOpen()
      else fx.playClose()
    }
  }
}
