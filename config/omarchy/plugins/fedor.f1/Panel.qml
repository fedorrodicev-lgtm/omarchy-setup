import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// Bar label counting down to the next Formula 1 race, with a popup holding
// the weekend schedule in local time, the drivers' championship and the last
// race's result. Data comes from the f1-status script next to this file,
// which caches the Jolpica API so the label survives being offline.
Panel {
  id: root
  moduleName: "fedor.f1"
  ipcTarget: "fedor.f1"

  property var f1Data: null
  property date now: new Date()

  readonly property string driverId: setting("driver", "leclerc")
  readonly property var next: f1Data && f1Data.next ? f1Data.next : null
  readonly property var sessions: next ? next.sessions : []
  readonly property var standings: f1Data && f1Data.standings ? f1Data.standings : { round: "", drivers: [] }
  readonly property var lastRace: f1Data && f1Data.last ? f1Data.last : null
  readonly property var liveSession: findLiveSession(sessions, now)
  readonly property var upcomingSession: findUpcomingSession(sessions, now)
  readonly property bool weekendStarted: sessions.length > 0 && new Date(sessions[0].start) <= now

  readonly property string countdown: next ? formatSpan(new Date(next.start) - now) : ""
  readonly property string label: {
    if (!next) return ""
    if (liveSession) return "  LIVE " + liveSession.name
    if (weekendStarted && upcomingSession)
      return "  " + upcomingSession.name + " " + formatSpan(new Date(upcomingSession.start) - now)
    return "  " + next.country + " " + countdown
  }

  readonly property real openPanelIndicatorWidth: button.labelWidth
  readonly property color accent: Commons.Color.accent

  function sessionMinutes(name) {
    if (name === "Race") return 120
    if (name.indexOf("Sprint") === 0) return 45
    return 60
  }

  function findLiveSession(list, at) {
    for (var i = 0; i < list.length; i++) {
      var start = new Date(list[i].start)
      var end = new Date(start.getTime() + sessionMinutes(list[i].name) * 60000)
      if (start <= at && at < end) return list[i]
    }
    return null
  }

  function findUpcomingSession(list, at) {
    for (var i = 0; i < list.length; i++)
      if (new Date(list[i].start) > at) return list[i]
    return null
  }

  function formatSpan(ms) {
    if (ms <= 0) return "now"
    var minutes = Math.floor(ms / 60000)
    var days = Math.floor(minutes / 1440)
    var hours = Math.floor((minutes % 1440) / 60)
    var mins = minutes % 60
    if (days > 0) return days + "d " + hours + "h"
    if (hours > 0) return hours + "h " + (mins < 10 ? "0" : "") + mins + "m"
    return mins + "m"
  }

  function sessionState(session) {
    if (liveSession && liveSession.start === session.start) return "live"
    if (upcomingSession && upcomingSession.start === session.start) return "next"
    return new Date(session.start) < now ? "past" : "later"
  }

  // Top ten plus the highlighted driver when they sit lower down.
  function standingsRows() {
    var drivers = standings.drivers || []
    var rows = drivers.slice(0, 10)
    for (var i = 10; i < drivers.length; i++)
      if (drivers[i].id === driverId) rows.push(drivers[i])
    return rows
  }

  function podiumRows() {
    var results = lastRace ? lastRace.results : []
    var rows = results.slice(0, 3)
    for (var i = 3; i < results.length; i++)
      if (results[i].id === driverId) rows.push(results[i])
    return rows
  }

  function refresh(force) {
    if (fetchProc.running) return
    fetchProc.command = force ? [scriptPath, "--refresh"] : [scriptPath]
    fetchProc.running = true
  }

  readonly property string scriptPath: decodeURIComponent(Qt.resolvedUrl("f1-status").toString().replace(/^file:\/\//, ""))

  Component.onCompleted: refresh(false)

  Process {
    id: fetchProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var parsed = JSON.parse(text)
          if (!parsed.error) root.f1Data = parsed
        } catch (e) {}
      }
    }
  }

  // The script answers from its cache, so polling it is cheap; it only
  // reaches the API when the cache is old or the race has passed.
  Timer { interval: 15 * 60 * 1000; running: true; repeat: true; onTriggered: root.refresh(false) }
  Timer { interval: 30 * 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.now = new Date() }

  visible: label !== ""
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.label
    labelVisible: true
    hasVisualContent: text !== ""
    horizontalMargin: 8.75
    verticalPadding: 8.75
    active: root.liveSession !== null
    tooltipText: ""

    onPressed: function(b) {
      if (b === Qt.MiddleButton) root.refresh(true)
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened && root.next !== null
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(360))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(14)

        // ---------- Hero: race name · round/place · countdown ----------
        Item {
          width: parent.width
          implicitHeight: Math.max(heroLabels.implicitHeight, heroCountdown.implicitHeight)

          Column {
            id: heroLabels
            anchors.left: parent.left
            anchors.right: heroCountdown.left
            anchors.rightMargin: Style.space(10)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              textFormat: Text.PlainText
              text: root.next ? root.next.name : ""
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
              width: parent.width
            }

            Text {
              textFormat: Text.PlainText
              text: root.next ? ("Round " + root.next.round + " · " + root.next.locality).toUpperCase() : ""
              color: Qt.darker(root.bar.foreground, 1.4)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.2
              elide: Text.ElideRight
              width: parent.width
            }
          }

          Text {
            id: heroCountdown
            textFormat: Text.PlainText
            text: root.liveSession ? "LIVE" : root.countdown
            color: root.liveSession ? root.accent : root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.display
            font.bold: true
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        // ---------- Weekend schedule in local time ----------
        Column {
          width: parent.width
          spacing: Style.space(6)

          PanelSectionHeader {
            text: "WEEKEND"
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
          }

          Repeater {
            model: root.sessions

            Item {
              id: sessionRow
              required property var modelData
              readonly property string phase: root.sessionState(modelData)
              readonly property bool highlighted: phase === "next" || phase === "live"
              width: parent.width
              implicitHeight: sessionName.implicitHeight
              opacity: phase === "past" ? 0.4 : 1

              Rectangle {
                visible: sessionRow.highlighted
                width: Style.space(2)
                height: parent.height
                x: -Style.space(8)
                color: root.accent
              }

              Cell {
                id: sessionName
                text: sessionRow.modelData.name
                color: sessionRow.highlighted ? root.accent : root.bar.foreground
                font.bold: sessionRow.highlighted
              }

              Cell {
                x: Style.space(130)
                text: Qt.formatDateTime(new Date(sessionRow.modelData.start), "ddd d MMM")
                opacity: 0.7
              }

              Cell {
                anchors.right: parent.right
                text: sessionRow.phase === "live" ? "LIVE" : Qt.formatDateTime(new Date(sessionRow.modelData.start), "HH:mm")
                color: sessionRow.highlighted ? root.accent : root.bar.foreground
                font.bold: sessionRow.highlighted
              }
            }
          }
        }

        PanelSeparator { foreground: root.bar.foreground }

        // ---------- Drivers' championship ----------
        Column {
          width: parent.width
          spacing: Style.space(6)

          PanelSectionHeader {
            text: "DRIVERS" + (root.standings.round ? " · AFTER ROUND " + root.standings.round : "")
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
          }

          Repeater {
            model: root.standingsRows()

            DriverRow {
              required property var modelData
              entry: modelData
              trailing: modelData.points
            }
          }
        }

        PanelSeparator {
          visible: root.lastRace !== null
          foreground: root.bar.foreground
        }

        // ---------- Last race ----------
        Column {
          visible: root.lastRace !== null
          width: parent.width
          spacing: Style.space(6)

          PanelSectionHeader {
            text: root.lastRace ? "LAST RACE · " + root.lastRace.name.replace(" Grand Prix", " GP").toUpperCase() : ""
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
          }

          Repeater {
            model: root.podiumRows()

            DriverRow {
              required property var modelData
              entry: modelData
              trailing: modelData.gap
            }
          }
        }
      }
    }
  }

  component Cell: Text {
    textFormat: Text.PlainText
    color: root.bar.foreground
    font.family: root.bar.fontFamily
    font.pixelSize: Style.font.bodySmall
  }

  // Position · code · surname · team · trailing value, with the configured
  // driver marked by an accent rule and accent text.
  component DriverRow: Item {
    id: driverRow
    property var entry: ({})
    property string trailing: ""
    readonly property bool mine: entry.id === root.driverId

    width: parent.width
    implicitHeight: posCell.implicitHeight

    Rectangle {
      visible: driverRow.mine
      width: Style.space(2)
      height: parent.height
      x: -Style.space(8)
      color: root.accent
    }

    Cell {
      id: posCell
      width: Style.space(22)
      text: driverRow.entry.pos
      opacity: driverRow.mine ? 1 : 0.6
      color: driverRow.mine ? root.accent : root.bar.foreground
    }

    Cell {
      x: Style.space(26)
      text: driverRow.entry.code
      font.bold: true
      color: driverRow.mine ? root.accent : root.bar.foreground
    }

    Cell {
      x: Style.space(66)
      width: Style.space(110)
      elide: Text.ElideRight
      text: driverRow.entry.name
      color: driverRow.mine ? root.accent : root.bar.foreground
      font.bold: driverRow.mine
    }

    Cell {
      x: Style.space(180)
      width: Style.space(100)
      elide: Text.ElideRight
      text: driverRow.entry.team
      opacity: 0.6
    }

    Cell {
      anchors.right: parent.right
      text: driverRow.trailing
      color: driverRow.mine ? root.accent : root.bar.foreground
      font.bold: driverRow.mine
    }
  }
}
