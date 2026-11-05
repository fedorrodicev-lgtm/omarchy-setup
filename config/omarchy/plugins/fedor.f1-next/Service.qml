import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Commons as Commons

// Desktop card for the next Grand Prix: the circuit outline, a countdown to
// lights out, and the forecast at the track for qualifying and the race.
// Data comes from the f1-next script next to this file, which caches for an
// hour so the card works offline.
Item {
  id: root

  property var shell: null

  property var info: null
  property date now: new Date()

  readonly property var race: info && info.race ? info.race : null
  readonly property string scriptPath: decodeURIComponent(Qt.resolvedUrl("f1-next").toString().replace(/^file:\/\//, ""))

  function formatSpan(ms) {
    if (ms <= 0) return "LIVE"
    var minutes = Math.floor(ms / 60000)
    var days = Math.floor(minutes / 1440)
    var hours = Math.floor((minutes % 1440) / 60)
    var mins = minutes % 60
    if (days > 0) return days + "d " + hours + "h"
    if (hours > 0) return hours + "h " + (mins < 10 ? "0" : "") + mins + "m"
    return mins + "m"
  }

  // WMO weather codes to Material Design weather glyphs from the Nerd Font.
  function weatherIcon(code) {
    var cp = 0xF0590                                    // cloudy
    if (code === 0) cp = 0xF0599                        // sunny
    else if (code <= 2) cp = 0xF0595                    // partly cloudy
    else if (code === 45 || code === 48) cp = 0xF0591   // fog
    else if (code >= 51 && code <= 61) cp = 0xF0597     // drizzle, light rain
    else if (code >= 63 && code <= 67) cp = 0xF0596     // rain
    else if (code >= 71 && code <= 77) cp = 0xF0598     // snow
    else if (code === 80) cp = 0xF0597
    else if (code >= 81 && code <= 82) cp = 0xF0596
    else if (code >= 85 && code <= 86) cp = 0xF0598
    else if (code >= 95) cp = 0xF0593                   // thunder
    return String.fromCodePoint(cp)
  }

  function trackPoints() {
    var points = []
    if (!race || !race.track) return points
    for (var i = 0; i < race.track.length; i += 2)
      points.push(Qt.point(race.track[i], race.track[i + 1]))
    if (points.length) points.push(points[0])
    return points
  }

  function refresh() {
    if (!fetchProc.running) fetchProc.running = true
  }

  Process {
    id: fetchProc
    command: [root.scriptPath]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var parsed = JSON.parse(text)
          if (!parsed.error) root.info = parsed
        } catch (e) {}
      }
    }
  }

  Component.onCompleted: refresh()

  // The card belongs to the Ferrari theme; any other theme hides it.
  readonly property string onlyTheme: "ferrari"
  property string themeName: ""

  FileView {
    path: Quickshell.env("HOME") + "/.local/state/omarchy/current/theme.name"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.themeName = String(text() || "").trim()
    onLoadFailed: root.themeName = ""
  }

  // Writing a PNG path into this file saves the card as it is drawn right
  // now, for checking the look without clearing the desktop:
  //   echo /tmp/card.png > ~/.cache/omarchy/f1-next-snapshot
  FileView {
    path: Quickshell.env("HOME") + "/.cache/omarchy/f1-next-snapshot"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      var target = String(text() || "").trim()
      if (target !== "") cardBody.grabToImage(function(result) { result.saveToFile(target) })
    }
  }

  // The script answers from its hourly cache, so polling it is cheap.
  Timer { interval: 15 * 60 * 1000; running: true; repeat: true; onTriggered: root.refresh() }
  Timer { interval: 30 * 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.now = new Date() }

  PanelWindow {
    id: card
    screen: Quickshell.screens[0]
    visible: root.race !== null && root.themeName === root.onlyTheme
    color: "transparent"

    // Top-left, below the bar, lined up with the window gaps. Normal respects
    // the bar's exclusive zone, so the top margin starts under it.
    anchors { top: true; left: true }
    margins { top: 10; left: 10 }
    implicitWidth: 250
    implicitHeight: content.implicitHeight + 2 * content.padding

    WlrLayershell.namespace: "fedor-f1-next"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Normal

    Item {
      id: cardBody
      anchors.fill: parent

      Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Commons.Color.background.r, Commons.Color.background.g, Commons.Color.background.b, 0.6)
        radius: Style.cornerRadius
        border.width: 1
        border.color: Qt.rgba(Commons.Color.accent.r, Commons.Color.accent.g, Commons.Color.accent.b, 0.7)
      }

      Column {
        id: content
        readonly property real padding: 12
        x: padding
        y: padding
        width: card.width - 2 * padding
        spacing: 8

        // ---------- Header: round · countdown, then the country ----------
        Item {
          width: parent.width
          implicitHeight: Math.max(labels.implicitHeight, countdown.implicitHeight)

          Column {
            id: labels
            anchors.left: parent.left
            anchors.right: countdown.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
              textFormat: Text.PlainText
              text: root.race ? "NEXT · ROUND " + root.race.round : ""
              color: Commons.Color.foreground
              opacity: 0.6
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.2
            }

            Text {
              textFormat: Text.PlainText
              text: root.race ? root.race.country : ""
              color: Commons.Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
              width: parent.width
            }
          }

          Text {
            id: countdown
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            textFormat: Text.PlainText
            text: root.race ? root.formatSpan(new Date(root.race.start) - root.now) : ""
            color: Commons.Color.accent
            font.family: Style.font.family
            font.pixelSize: Style.font.heading
            font.bold: true
          }
        }

        // ---------- Circuit outline ----------
        Canvas {
          id: trackCanvas
          readonly property real inset: 4
          readonly property real s: (width - 2 * inset) / 1000
          width: parent.width
          height: root.race && root.race.height ? root.race.height * s + 2 * inset : 0
          visible: height > 0
          renderStrategy: Canvas.Cooperative

          readonly property var raceRef: root.race
          onRaceRefChanged: requestPaint()
          onWidthChanged: requestPaint()
          onHeightChanged: requestPaint()

          onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var points = root.trackPoints()
            if (points.length < 2) return
            var fg = Commons.Color.foreground
            ctx.strokeStyle = Qt.rgba(fg.r, fg.g, fg.b, 0.75)
            ctx.lineWidth = 2.5
            ctx.lineJoin = "round"
            ctx.lineCap = "round"
            ctx.beginPath()
            ctx.moveTo(inset + points[0].x * s, inset + points[0].y * s)
            for (var i = 1; i < points.length; i++)
              ctx.lineTo(inset + points[i].x * s, inset + points[i].y * s)
            ctx.stroke()
          }
        }

        Text {
          textFormat: Text.PlainText
          text: root.race ? root.race.circuit.toUpperCase() : ""
          color: Commons.Color.foreground
          opacity: 0.6
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          font.bold: true
          font.letterSpacing: 1
          elide: Text.ElideRight
          width: parent.width
        }

        Rectangle {
          width: parent.width
          height: 1
          color: Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.12)
        }

        // ---------- Qualifying and race: local time · forecast at the track ----------
        Repeater {
          model: root.race ? root.race.sessions : []

          Item {
            id: row
            required property var modelData
            readonly property var weather: modelData.weather
            width: parent.width
            implicitHeight: sessionName.implicitHeight

            Cell {
              id: sessionName
              text: row.modelData.name
              font.bold: true
            }

            Cell {
              x: 52
              text: Qt.formatDateTime(new Date(row.modelData.start), "ddd HH:mm")
              opacity: 0.7
            }

            Cell {
              anchors.right: rainCell.left
              anchors.rightMargin: 10
              text: row.weather ? root.weatherIcon(row.weather.code) + " " + Math.round(row.weather.temp) + "°" : "—"
              opacity: row.weather ? 1 : 0.5
            }

            Cell {
              id: rainCell
              anchors.right: parent.right
              width: 40
              horizontalAlignment: Text.AlignRight
              visible: row.weather !== null
              text: row.weather ? String.fromCodePoint(0xF058C) + " " + row.weather.rain + "%" : ""
              color: row.weather && row.weather.rain >= 50 ? Commons.Color.accent : Commons.Color.foreground
              font.bold: row.weather && row.weather.rain >= 50
            }
          }
        }
      }
    }
  }

  component Cell: Text {
    textFormat: Text.PlainText
    color: Commons.Color.foreground
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
  }
}
