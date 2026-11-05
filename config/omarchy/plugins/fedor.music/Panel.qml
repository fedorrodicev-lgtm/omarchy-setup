import QtQuick
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// Bar label with the playing track and a thin accent line under it that
// fills like a lap counter, plus a popup in the style of the F1 panel:
// cover art, seekable progress, transport controls and the other sources.
// Talks to MPRIS directly: Omarchy only hands its media service to the bar
// itself, not to third-party widgets.
Panel {
  id: root
  moduleName: "fedor.music"
  ipcTarget: "fedor.music"

  property string preferredKey: ""

  // playerctld only mirrors another player, so it would show every track twice.
  readonly property var sources: {
    var list = Mpris.players ? Mpris.players.values : []
    return list.filter(function(p) {
      return p && p.dbusName.indexOf("playerctld") === -1 && (p.trackTitle || p.trackArtist)
    })
  }
  // The source picked in the popup wins while it plays; otherwise whatever is playing.
  readonly property var player: {
    var preferred = null
    for (var i = 0; i < sources.length; i++)
      if (keyOf(sources[i]) === preferredKey) preferred = sources[i]
    if (preferred && preferred.isPlaying) return preferred
    for (var j = 0; j < sources.length; j++)
      if (sources[j].isPlaying) return sources[j]
    return preferred || (sources.length > 0 ? sources[0] : null)
  }

  readonly property string title: player ? (player.trackTitle || "") : ""
  readonly property string artist: player ? (player.trackArtist || "") : ""
  readonly property string album: player && player.trackAlbum ? player.trackAlbum : ""
  readonly property string artUrl: player && player.trackArtUrl ? player.trackArtUrl : ""
  readonly property string playerName: player ? (player.identity || player.desktopEntry || "") : ""
  readonly property bool hasMedia: title !== "" || artist !== ""
  readonly property bool playing: player ? !!player.isPlaying : false

  readonly property bool hasLength: player !== null && player.lengthSupported && player.length > 0
  readonly property real length: hasLength ? player.length : 0
  readonly property real position: player && player.positionSupported ? Math.min(player.position, length || player.position) : 0
  readonly property real progress: hasLength ? Math.max(0, Math.min(1, position / length)) : 0

  readonly property int maxChars: setting("maxChars", 32)
  readonly property string label: {
    if (!hasMedia) return ""
    var text = title && artist ? title + " · " + artist : (title || artist)
    if (text.length > maxChars) text = text.slice(0, maxChars - 1).trim() + "…"
    return (playing ? "󰎈  " : "󰏤  ") + text
  }

  readonly property real openPanelIndicatorWidth: button.labelWidth
  readonly property color accent: Commons.Color.accent

  function formatTime(seconds) {
    if (!(seconds >= 0)) return "0:00"
    var s = Math.floor(seconds)
    var h = Math.floor(s / 3600)
    var m = Math.floor((s % 3600) / 60)
    var sec = s % 60
    var mm = h > 0 && m < 10 ? "0" + m : "" + m
    return (h > 0 ? h + ":" : "") + mm + ":" + (sec < 10 ? "0" : "") + sec
  }

  function keyOf(p) {
    return p ? p.dbusName : ""
  }

  function run(action) {
    if (!player) return
    if (action === "next" && player.canGoNext) player.next()
    else if (action === "previous" && player.canGoPrevious) player.previous()
    else if (action === "playPause" && player.canTogglePlaying) player.togglePlaying()
    preferredKey = keyOf(player)
  }

  // MPRIS doesn't push position updates; ask the player for it while it plays.
  Timer {
    interval: 1000
    repeat: true
    running: root.playing && root.player && root.player.positionSupported
    triggeredOnStart: true
    onTriggered: root.player.positionChanged()
  }

  visible: hasMedia
  implicitWidth: hasMedia ? button.implicitWidth : 0
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
    dimmed: !root.playing
    tooltipText: ""

    onPressed: function(b) {
      if (b === Qt.MiddleButton) root.run("playPause")
      else root.toggle()
    }
    onWheelMoved: function(delta) { root.run(delta > 0 ? "previous" : "next") }
  }

  // Lap line: a faint track under the label with the elapsed part in accent.
  // Hidden while the popup is open, where the bar draws its own underline.
  Item {
    visible: root.hasLength && !root.opened && !root.bar.vertical
    width: button.labelWidth
    height: Math.max(2, Style.space(2))
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Style.space(5)
    opacity: root.playing ? 1 : 0.5

    Rectangle {
      anchors.fill: parent
      radius: height / 2
      color: root.bar.barForeground
      opacity: 0.15
    }

    Rectangle {
      width: parent.width * root.progress
      height: parent.height
      radius: height / 2
      color: root.accent
      Behavior on width { NumberAnimation { duration: 900; easing.type: Easing.Linear } }
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened && root.hasMedia
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(340))
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

        // ---------- Hero: cover · title · artist · album/player ----------
        Item {
          width: parent.width
          implicitHeight: cover.height

          ClippingRectangle {
            id: cover
            width: Style.space(72)
            height: width
            radius: Style.cornerRadius
            color: Style.normalFillFor(root.bar.foreground, root.accent)

            Image {
              anchors.fill: parent
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              sourceSize.width: width * 2
              sourceSize.height: height * 2
              source: root.artUrl
              visible: status === Image.Ready
            }

            Text {
              anchors.centerIn: parent
              visible: root.artUrl === ""
              text: "󰝚"
              color: root.accent
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.displayLarge
            }
          }

          Column {
            anchors.left: cover.right
            anchors.leftMargin: Style.space(12)
            anchors.right: parent.right
            anchors.verticalCenter: cover.verticalCenter
            spacing: Style.space(2)

            Text {
              textFormat: Text.PlainText
              text: root.title || root.playerName
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
              width: parent.width
            }

            Text {
              textFormat: Text.PlainText
              visible: text !== ""
              text: root.artist
              color: root.accent
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.body
              font.bold: true
              elide: Text.ElideRight
              width: parent.width
            }

            Text {
              textFormat: Text.PlainText
              text: [root.album, root.playerName].filter(function(s) { return s !== "" }).join(" · ").toUpperCase()
              color: Qt.darker(root.bar.foreground, 1.4)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.2
              elide: Text.ElideRight
              width: parent.width
            }
          }
        }

        // ---------- Progress: seek bar with elapsed and remaining ----------
        Column {
          visible: root.hasLength
          width: parent.width
          spacing: Style.space(6)

          PanelSlider {
            id: seek
            bar: root.bar
            width: parent.width
            minimum: 0
            maximum: Math.max(1, root.length)
            step: 1
            value: root.position
            enabled: root.player && root.player.canSeek
            fillColor: root.accent
            knobColor: root.accent
            onReleased: function(v) { if (root.player && root.player.canSeek) root.player.position = v }
          }

          Item {
            width: parent.width
            implicitHeight: elapsed.implicitHeight

            Cell {
              id: elapsed
              text: root.formatTime(seek.dragging ? seek.liveValue : root.position)
              color: root.playing ? root.accent : root.bar.foreground
              font.bold: true
            }

            Cell {
              anchors.right: parent.right
              text: "-" + root.formatTime(root.length - (seek.dragging ? seek.liveValue : root.position))
              opacity: 0.6
            }
          }
        }

        // ---------- Transport ----------
        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: Style.space(10)

          Button {
            iconText: "󰒮"
            foreground: root.bar.foreground
            enabled: root.player && root.player.canGoPrevious
            opacity: enabled ? 1 : 0.4
            onClicked: root.run("previous")
          }

          Button {
            iconText: root.playing ? "󰏤" : "󰐊"
            foreground: root.accent
            iconSize: Style.font.iconLarge
            horizontalPadding: Style.spacing.panelGap
            bordered: true
            enabled: root.player && root.player.canTogglePlaying
            opacity: enabled ? 1 : 0.4
            onClicked: root.run("playPause")
          }

          Button {
            iconText: "󰒭"
            foreground: root.bar.foreground
            enabled: root.player && root.player.canGoNext
            opacity: enabled ? 1 : 0.4
            onClicked: root.run("next")
          }
        }

        PanelSeparator {
          visible: root.sources.length > 1
          foreground: root.bar.foreground
        }

        // ---------- Other sources, picked like a driver in the standings ----------
        Column {
          visible: root.sources.length > 1
          width: parent.width
          spacing: Style.space(6)

          PanelSectionHeader {
            text: "SOURCES"
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
          }

          Repeater {
            model: root.sources

            Item {
              id: sourceRow
              required property var modelData
              readonly property bool current: root.keyOf(modelData) === root.keyOf(root.player)
              width: parent.width
              implicitHeight: sourceName.implicitHeight

              Rectangle {
                visible: sourceRow.current
                width: Style.space(2)
                height: parent.height
                x: -Style.space(8)
                color: root.accent
              }

              Cell {
                id: sourceName
                width: Style.space(22)
                text: sourceRow.modelData.isPlaying ? "󰎈" : "󰏤"
                color: sourceRow.current ? root.accent : root.bar.foreground
                opacity: sourceRow.current ? 1 : 0.6
              }

              Cell {
                x: Style.space(26)
                width: parent.width - x - Style.space(110)
                elide: Text.ElideRight
                text: sourceRow.modelData.trackTitle || sourceRow.modelData.identity || ""
                color: sourceRow.current ? root.accent : root.bar.foreground
                font.bold: sourceRow.current
              }

              Cell {
                anchors.right: parent.right
                width: Style.space(100)
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
                text: sourceRow.modelData.identity || sourceRow.modelData.desktopEntry || ""
                opacity: 0.6
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.preferredKey = root.keyOf(sourceRow.modelData)
              }
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
}
