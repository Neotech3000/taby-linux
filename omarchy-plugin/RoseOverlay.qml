import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui

Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool opened: false
  property bool busy: false
  property string section: "chat"
  property string pendingAction: ""
  property string processError: ""
  property var aiHistory: []
  property string deviceSummary: "Not checked"
  property string selectedAnimation: "idle_01_loop"
  property bool refreshTasksAfterAction: false

  readonly property string pluginId: manifest && manifest.id
    ? String(manifest.id) : "enochlawrence.rose-assistant"
  readonly property string bridgePath: String(Qt.resolvedUrl("bin/rose-bridge"))
    .replace(/^file:\/\//, "")
  readonly property string faceUrl: {
    var override = Quickshell.env("TABY_C6_ASSETS")
    if (override && override.length > 0)
      return "file://" + override + "/a/5e63dbe6.gif"
    return ""
  }
  readonly property string fontFamily: Style.font.family
  readonly property color textColor: Color.foreground
  readonly property color mutedColor: Qt.rgba(0.78, 0.81, 0.86, 0.72)
  readonly property color cardColor: Color.menu.background
  readonly property color borderColor: Color.menu.border
  readonly property color roseColor: "#e9a2c7"

  ListModel { id: messages }
  ListModel { id: taskItems }
  ListModel { id: animationItems }

  function open(payloadJson) {
    root.opened = true
    if (messages.count === 0)
      appendMessage("assistant", "I’m Rose. Ask me something, or give me a local task.")
    Qt.callLater(function() {
      if (!root.opened) return
      promptField.forceActiveFocus()
      root.runBridge("tasks-list", [])
    })
  }

  function close() {
    root.opened = false
    if (bridgeProc.running) bridgeProc.running = false
    root.busy = false
    promptField.text = ""
  }

  function dismiss() {
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide(root.pluginId)
    else root.close()
  }

  function toggle() {
    if (root.opened) root.dismiss()
    else root.open("{}")
  }

  function appendMessage(role, text) {
    messages.append({"role": role, "text": String(text || "")})
    if (messages.count > 80) messages.remove(0)
    Qt.callLater(function() { transcript.positionViewAtEnd() })
  }

  function runBridge(action, args) {
    if (bridgeProc.running) {
      root.processError = "One action is still running. Wait for it to finish."
      return
    }
    root.pendingAction = action
    root.processError = ""
    root.busy = true
    bridgeProc.command = [root.bridgePath, action].concat(args || [])
    bridgeProc.running = true
  }

  function submitPrompt() {
    var value = String(promptField.text || "").trim()
    if (!value || root.busy) return
    promptField.text = ""
    root.appendMessage("user", value)

    var lower = value.toLowerCase()
    var taskMatch = /^(?:add|create)\s+(?:a\s+)?task(?:\s+to)?\s+(.+)$/.exec(value)
    var noteMatch = /^(?:note|save note|add note)\s+(.+)$/.exec(value)
    if (taskMatch) {
      root.runBridge("task-add", [taskMatch[1]])
    } else if (lower === "tasks" || lower === "list tasks" || lower === "show tasks") {
      root.runBridge("tasks-list", [])
    } else if (noteMatch) {
      var pieces = noteMatch[1].split(":")
      root.runBridge("note-add", [pieces.shift(), pieces.join(":")])
    } else if (lower === "notes" || lower === "list notes") {
      root.runBridge("notes-list", [])
    } else if (lower.startsWith("remind me to ")) {
      root.appendMessage("assistant", "Use “remind me to … in 10 minutes” in the GTK companion for reminders.")
    } else {
      root.aiHistory.push({"role": "user", "content": value})
      if (root.aiHistory.length > 10) root.aiHistory.shift()
      root.runBridge("ask", [JSON.stringify(root.aiHistory)])
    }
  }

  function applyResponse(raw) {
    var response
    try { response = JSON.parse(String(raw || "").trim()) }
    catch (e) { root.processError = "The assistant returned an unreadable response."; return }
    if (!response || response.ok !== true) {
      root.processError = response && response.error ? String(response.error) : "The action failed."
      root.appendMessage("assistant", root.processError)
      return
    }

    var data = response.data || {}
    if (root.pendingAction === "ask") {
      var answer = data.text || "I couldn't form a reply."
      root.aiHistory.push({"role": "assistant", "content": answer})
      if (root.aiHistory.length > 10) root.aiHistory.shift()
      root.appendMessage("assistant", answer)
    } else if (root.pendingAction === "task-add") {
      root.appendMessage("assistant", data.text || "Task saved locally.")
      root.setTasks(data.tasks || [])
    } else if (root.pendingAction === "tasks-list") {
      root.setTasks(data.tasks || [])
      if (data.text) root.appendMessage("assistant", data.text)
    } else if (root.pendingAction === "task-toggle") {
      root.setTasks(data.tasks || [])
    } else if (root.pendingAction === "note-add") {
      root.appendMessage("assistant", data.text || "Note saved locally.")
    } else if (root.pendingAction === "notes-list") {
      root.appendMessage("assistant", data.text || "No notes yet.")
    } else if (root.pendingAction === "device-status") {
      root.deviceSummary = data.text || "No device found."
      animationItems.clear()
      for (var animationIndex = 0; animationIndex < (data.animations || []).length; animationIndex++)
        animationItems.append({"name": data.animations[animationIndex]})
    } else if (root.pendingAction === "device-play") {
      root.deviceSummary = data.text || "Animation command sent."
    } else if (root.pendingAction === "animations") {
      animationItems.clear()
      for (var i = 0; i < (data.animations || []).length; i++)
        animationItems.append({"name": data.animations[i]})
    }
  }

  function setTasks(items) {
    taskItems.clear()
    for (var i = 0; i < items.length; i++) taskItems.append(items[i])
  }

  Process {
    id: bridgeProc
    command: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyResponse(text)
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var detail = String(text || "").trim()
        if (detail !== "") root.processError = detail.slice(0, 300)
      }
    }
    onExited: function(exitCode) {
      root.busy = false
      if (exitCode !== 0 && root.processError !== "")
        root.appendMessage("assistant", root.processError)
    }
  }

  PanelWindow {
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "rose-taby-assistant"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Rectangle {
      anchors.fill: parent
      color: Qt.rgba(0.025, 0.03, 0.045, 0.78)
      MouseArea { anchors.fill: parent; onClicked: root.dismiss() }
    }

    Item {
      id: focusScope
      anchors.fill: parent
      focus: true
      Keys.priority: Keys.BeforeItem
      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
          root.dismiss()
          event.accepted = true
        }
      }

      Rectangle {
        id: card
        width: Math.min(1000, focusScope.width - 48)
        height: Math.min(720, focusScope.height - 48)
        anchors.centerIn: parent
        radius: 28
        color: root.cardColor
        border.color: root.borderColor
        border.width: 1
        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: 22
          spacing: 16

          RowLayout {
            Layout.fillWidth: true
            spacing: 14
            Rectangle {
              width: 70; height: 70; radius: 35
              color: "#10131b"
              border.color: Qt.rgba(0.91, 0.64, 0.78, 0.72)
              border.width: 2
              Rectangle {
                anchors.fill: parent; anchors.margins: 5; radius: 30
                color: "transparent"
                border.color: Qt.rgba(0.91, 0.64, 0.78, 0.22)
                border.width: 1
              }
              Image {
                id: fallbackFace
                anchors.centerIn: parent
                width: 42; height: 42
                source: Qt.resolvedUrl("../taby.svg")
                fillMode: Image.PreserveAspectFit
                visible: animatedFace.status !== Image.Ready
              }
              AnimatedImage {
                id: animatedFace
                anchors.centerIn: parent
                width: 36; height: 54
                source: root.faceUrl
                fillMode: Image.PreserveAspectFit
                playing: root.opened
                visible: status === Image.Ready
              }
            }
            ColumnLayout {
              Layout.fillWidth: true
              spacing: 2
              Text { text: "ROSE / 01"; color: root.textColor; font.pixelSize: 19; font.bold: true; font.letterSpacing: 2 }
              Text { text: "TABY × OMARCHY · PERSONAL ASSISTANT"; color: root.mutedColor; font.pixelSize: 9; font.letterSpacing: 1.1 }
            }
            Text { text: root.busy ? "THINKING" : "READY"; color: root.busy ? root.roseColor : "#94d7b0"; font.pixelSize: 10; font.bold: true }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Repeater {
              model: [{"id":"chat","label":"Chat"},{"id":"tasks","label":"Tasks"},{"id":"device","label":"Physical Taby"}]
              delegate: Rectangle {
                Layout.fillWidth: true
                implicitHeight: 38
                radius: 11
                color: root.section === modelData.id ? Qt.rgba(0.91,0.64,0.78,0.18) : Qt.rgba(1,1,1,0.035)
                Text { anchors.centerIn: parent; text: modelData.label; color: root.section === modelData.id ? root.roseColor : root.mutedColor; font.pixelSize: 12 }
                MouseArea { anchors.fill: parent; onClicked: { root.section = modelData.id; if (modelData.id === "device") root.runBridge("device-status", []) } }
              }
            }
          }

          StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.section === "chat" ? 0 : root.section === "tasks" ? 1 : 2

            ColumnLayout {
              spacing: 12
              ListView {
                id: transcript
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true; spacing: 9
                model: messages
                delegate: Item {
                  width: transcript.width
                  height: bubble.height + 6
                  Rectangle {
                    id: bubble
                    width: Math.min(transcript.width * 0.9, textItem.implicitWidth + 28)
                    height: textItem.implicitHeight + 22
                    x: model.role === "user" ? transcript.width - width : 0
                    radius: 14
                    color: model.role === "user" ? Qt.rgba(0.91,0.64,0.78,0.15) : Qt.rgba(1,1,1,0.045)
                    Text {
                      id: textItem
                      anchors.centerIn: parent
                      width: Math.min(transcript.width * 0.9 - 28, implicitWidth)
                      text: model.text
                      wrapMode: Text.Wrap
                      color: root.textColor
                      font.pixelSize: 13
                    }
                  }
                }
              }
              RowLayout {
                Layout.fillWidth: true
                TextField {
                  id: promptField
                  Layout.fillWidth: true
                  placeholderText: "Ask Rose, add a task, or save a note…"
                  onAccepted: root.submitPrompt()
                }
                Rectangle {
                  width: 78; height: 40; radius: 12
                  color: root.busy ? "#3d3b43" : "#9a6388"
                  Text { anchors.centerIn: parent; text: root.busy ? "…" : "Send"; color: "white"; font.pixelSize: 12; font.bold: true }
                  MouseArea { anchors.fill: parent; enabled: !root.busy; onClicked: root.submitPrompt() }
                }
              }
              RowLayout {
                Layout.fillWidth: true
                spacing: 7
                Repeater {
                  model: ["List tasks", "Add task", "Physical Taby"]
                  delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 30; radius: 10
                    color: Qt.rgba(0.91, 0.64, 0.78, 0.075)
                    border.color: Qt.rgba(0.91, 0.64, 0.78, 0.18)
                    Text { anchors.centerIn: parent; text: modelData; color: root.mutedColor; font.pixelSize: 10 }
                    MouseArea { anchors.fill: parent; onClicked: root.quickAction(modelData) }
                  }
                }
              }
              Text {
                Layout.fillWidth: true
                text: "OpenCode uses its configured provider (may be remote/paid); local task/note commands stay on-device."
                color: root.mutedColor; font.pixelSize: 10; wrapMode: Text.Wrap
              }
            }

            ColumnLayout {
              spacing: 10
              RowLayout {
                Layout.fillWidth: true
                TextField { id: taskField; Layout.fillWidth: true; placeholderText: "Add a local task…"; onAccepted: root.addTask() }
                Rectangle {
                  width: 72; height: 38; radius: 11; color: "#9a6388"
                  Text { anchors.centerIn: parent; text: "Add"; color: "white"; font.pixelSize: 12; font.bold: true }
                  MouseArea { anchors.fill: parent; onClicked: root.addTask() }
                }
              }
              ListView {
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 8
                model: taskItems
                delegate: Rectangle {
                  width: ListView.view.width; height: 48; radius: 12
                  color: Qt.rgba(1,1,1,0.04)
                  RowLayout {
                    anchors.fill: parent; anchors.margins: 10; spacing: 8
                    Text { Layout.fillWidth: true; text: model.title; color: model.done ? root.mutedColor : root.textColor; font.pixelSize: 12; elide: Text.ElideRight }
                    Text { text: model.done ? "DONE" : "OPEN"; color: root.roseColor; font.pixelSize: 9; font.bold: true }
                    Rectangle {
                      width: 54; height: 28; radius: 8; color: "#303643"
                      Text { anchors.centerIn: parent; text: model.done ? "Reopen" : "Done"; color: root.textColor; font.pixelSize: 9 }
                      MouseArea { anchors.fill: parent; onClicked: root.toggleTask(model.id, !model.done) }
                    }
                  }
                }
              }
              Rectangle {
                Layout.fillWidth: true; height: 32; radius: 9; color: "#252b35"
                Text { anchors.centerIn: parent; text: "Refresh tasks"; color: root.mutedColor; font.pixelSize: 10 }
                MouseArea { anchors.fill: parent; onClicked: root.runBridge("tasks-list", []) }
              }
            }

            ColumnLayout {
              spacing: 14
              Text { Layout.fillWidth: true; text: root.deviceSummary; color: root.textColor; font.pixelSize: 13; wrapMode: Text.Wrap }
              RowLayout {
                Layout.fillWidth: true
                ComboBox { id: animationPicker; Layout.fillWidth: true; model: animationItems; textRole: "name" }
                Rectangle {
                  width: 78; height: 38; radius: 11; color: "#9a6388"
                  Text { anchors.centerIn: parent; text: "Play"; color: "white"; font.pixelSize: 12; font.bold: true }
                  MouseArea { anchors.fill: parent; onClicked: root.playSelectedAnimation() }
                }
              }
              Rectangle {
                Layout.fillWidth: true; height: 32; radius: 9; color: "#252b35"
                Text { anchors.centerIn: parent; text: "Scan USB device"; color: root.mutedColor; font.pixelSize: 10 }
                MouseArea { anchors.fill: parent; onClicked: root.runBridge("device-status", []) }
              }
              Text { Layout.fillWidth: true; text: "No touch input on this C6 board. USB commands are limited to animations in its bundled catalog."; color: root.mutedColor; font.pixelSize: 10; wrapMode: Text.Wrap }
            }
          }
        }
      }

      Text { anchors.bottom: parent.bottom; anchors.bottomMargin: 24; anchors.horizontalCenter: parent.horizontalCenter; text: root.processError; color: "#ff9caa"; font.pixelSize: 11 }
    }
  }

  function addTask() {
    var title = String(taskField.text || "").trim()
    if (title !== "") {
      taskField.text = ""
      root.runBridge("task-add", [title])
    }
  }

  function toggleTask(taskId, done) {
    root.runBridge("task-toggle", [String(taskId), done ? "done" : "open"])
  }

  function playSelectedAnimation() {
    var name = animationPicker.currentText
    if (name) root.runBridge("device-play", [String(name)])
  }

  function quickAction(label) {
    if (label === "List tasks") root.runBridge("tasks-list", [])
    else if (label === "Add task") {
      root.section = "tasks"
      Qt.callLater(function() { taskField.forceActiveFocus() })
    } else {
      root.section = "device"
      root.runBridge("device-status", [])
    }
  }
}
