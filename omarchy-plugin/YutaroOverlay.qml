pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui as OmarchyUi

Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool opened: false
  property bool busy: false
  property string section: "chat"
  property string pendingAction: ""
  property string processError: ""
  property string backend: "opencode"
  property string modelRef: "opencode/big-pickle"
  property var modelOptions: []
  property string backendSummary: "OpenCode · Big Pickle · checking"
  property var aiHistory: []
  property string deviceSummary: "Not checked"
  property bool backendChecked: false
  property bool pendingBackendStatus: false
  property bool clearNoteDraftOnSave: false

  readonly property string pluginId: manifest && manifest.id
    ? String(manifest.id) : "enochlawrence.yutaro-assistant"
  readonly property string bridgePath: String(Qt.resolvedUrl("bin/rose-bridge"))
    .replace(/^file:\/\//, "")
  readonly property string faceUrl: {
    var override = Quickshell.env("TABY_C6_ASSETS")
    if (override && override.length > 0)
      return "file://" + override + "/a/5e63dbe6.gif"
    return ""
  }
  readonly property color textColor: Color.foreground
  readonly property color mutedColor: Color.muted
  readonly property color cardColor: Qt.rgba(Color.menu.background.r, Color.menu.background.g,
                                               Color.menu.background.b, 0.99)
  readonly property color borderColor: Color.menu.border
  readonly property color scrimColor: Qt.rgba(Color.background.r, Color.background.g,
                                                Color.background.b, 0.92)
  readonly property color roseColor: "#e9a2c7"

  ListModel { id: messages }
  ListModel { id: taskItems }
  ListModel { id: noteItems }
  ListModel { id: animationItems }

  function open(payloadJson) {
    root.opened = true
    root.backendChecked = false
    if (messages.count === 0)
      appendMessage("assistant", "I’m Yutaro. Ask me something, or give me a local task.")
    Qt.callLater(function() {
      if (!root.opened) return
      promptField.forceActiveFocus()
      root.runBridge("backend-options", [])
    })
  }

  function close() {
    root.opened = false
    root.clearNoteDraftOnSave = false
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
      root.runBridge("ask", [root.backend, root.modelRef, JSON.stringify(root.aiHistory)])
    }
  }

  function applyResponse(raw) {
    var response
    try { response = JSON.parse(String(raw || "").trim()) }
    catch (e) {
      root.processError = "The assistant returned an unreadable response."
      if (root.pendingAction === "note-add") root.clearNoteDraftOnSave = false
      return
    }
    if (!response || response.ok !== true) {
      root.processError = response && response.error ? String(response.error) : "The action failed."
      if (root.pendingAction === "note-add") root.clearNoteDraftOnSave = false
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
      if (!root.backendChecked && root.opened)
        root.pendingBackendStatus = true
    } else if (root.pendingAction === "backend-status") {
      root.backendSummary = data.text || "OpenCode · status unavailable"
      root.backendChecked = true
    } else if (root.pendingAction === "backend-options") {
      root.backend = data.backend || root.backend
      root.modelRef = data.model || ""
      root.backendSummary = data.text || "No model available"
      var options = []
      for (var modelIndex = 0; modelIndex < (data.models || []).length; modelIndex++)
        options.push({"value": data.models[modelIndex].id, "label": data.models[modelIndex].label})
      if (options.length === 0)
        options.push({"value": "", "label": data.text || "No model available"})
      root.modelOptions = options
      modelPicker.enabled = !!data.available
      root.setTasks(data.tasks || [])
      root.backendChecked = true
    } else if (root.pendingAction === "model-select") {
      root.modelRef = data.model || root.modelRef
      var selectedOption = null
      for (var selectedIndex = 0; selectedIndex < root.modelOptions.length; selectedIndex++) {
        if (root.modelOptions[selectedIndex].value === root.modelRef)
          selectedOption = root.modelOptions[selectedIndex]
      }
      if (selectedOption) {
        root.backendSummary = root.backend === "opencode"
          ? "OpenCode · " + selectedOption.label + " · may be remote/paid"
          : "Local Ollama · " + selectedOption.label + " · stays on-device"
      }
    } else if (root.pendingAction === "task-toggle") {
      root.setTasks(data.tasks || [])
    } else if (root.pendingAction === "note-add") {
      if (root.section === "chat") root.appendMessage("assistant", data.text || "Note saved locally.")
      root.setNotes(data.notes || [])
      if (root.clearNoteDraftOnSave) {
        noteTitleField.text = ""
        noteBodyField.text = ""
        root.clearNoteDraftOnSave = false
      }
    } else if (root.pendingAction === "notes-list") {
      root.setNotes(data.notes || [])
      if (root.section === "chat" && data.text) root.appendMessage("assistant", data.text)
    } else if (root.pendingAction === "device-status") {
      root.deviceSummary = data.text || "No device found."
      animationItems.clear()
      for (var animationIndex = 0; animationIndex < (data.animations || []).length; animationIndex++)
        animationItems.append({"name": data.animations[animationIndex]})
    } else if (root.pendingAction === "device-play") {
      root.deviceSummary = data.text || "Animation command sent."
    }
  }

  function setTasks(items) {
    taskItems.clear()
    for (var i = 0; i < items.length; i++)
      taskItems.append({"taskId": String(items[i].id), "title": String(items[i].title), "done": Boolean(items[i].done)})
  }

  function setNotes(items) {
    noteItems.clear()
    for (var i = 0; i < items.length; i++)
      noteItems.append({"noteTitle": String(items[i].title), "noteBody": String(items[i].body || "")})
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
      if (root.pendingBackendStatus && root.opened) {
        root.pendingBackendStatus = false
        Qt.callLater(function() { root.runBridge("backend-status", []) })
      }
    }
  }

  PanelWindow {
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "yutaro-taby-assistant"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Rectangle {
      anchors.fill: parent
      color: root.scrimColor
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
        width: Math.max(0, Math.min(1000, focusScope.width - 40))
        height: Math.max(0, Math.min(720, focusScope.height - 40))
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
                source: Qt.resolvedUrl("YutaroFace.svg")
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
              Text { text: "YUTARO / 01"; color: root.textColor; font.pixelSize: 19; font.bold: true; font.letterSpacing: 2 }
              Text { text: "TABY × OMARCHY · PERSONAL ASSISTANT"; color: root.mutedColor; font.pixelSize: 9; font.letterSpacing: 1.1 }
            }
            ColumnLayout {
              spacing: 4
              Text { text: root.busy ? "THINKING" : "READY"; color: root.busy ? root.roseColor : "#94d7b0"; font.pixelSize: 10; font.bold: true; horizontalAlignment: Text.AlignRight; Layout.alignment: Qt.AlignRight }
              Text { text: root.backendSummary; color: root.mutedColor; font.pixelSize: 9; horizontalAlignment: Text.AlignRight; Layout.alignment: Qt.AlignRight }
            }
            OmarchyUi.Button {
              Layout.preferredWidth: 34; Layout.preferredHeight: 34
              text: "×"; foreground: root.mutedColor; accent: root.roseColor
              horizontalPadding: 0; verticalPadding: 0; focusable: true
              tooltipText: "Close assistant"
              onClicked: root.dismiss()
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Repeater {
              model: [{"id":"chat","label":"Chat"},{"id":"tasks","label":"Tasks"},{"id":"notes","label":"Notes"},{"id":"device","label":"Device"}]
              delegate: OmarchyUi.Button {
                required property var modelData
                Layout.fillWidth: true
                text: modelData.label
                selected: root.section === modelData.id
                foreground: root.textColor
                accent: root.roseColor
                focusable: true
                onClicked: {
                  root.section = modelData.id
                  if (modelData.id === "device") root.runBridge("device-status", [])
                  else if (modelData.id === "notes") root.runBridge("notes-list", [])
                }
              }
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: 10
            OmarchyUi.Dropdown {
              id: providerPicker
              Layout.fillWidth: true
              label: "AI source"
              options: [
                {"value": "opencode", "label": "OpenCode"},
                {"value": "ollama", "label": "Local Ollama"}
              ]
              value: root.backend
              accent: root.roseColor
              onChanged: function(value) { root.selectBackend(value) }
            }
            OmarchyUi.Dropdown {
              id: modelPicker
              Layout.fillWidth: true
              label: "Model"
              options: root.modelOptions
              value: root.modelRef
              accent: root.roseColor
              onChanged: function(value) { root.selectModel(value) }
            }
            OmarchyUi.Button {
              text: "↻"; tooltipText: "Refresh model list"
              foreground: root.mutedColor; accent: root.roseColor
              focusable: true
              onClicked: root.refreshModels()
            }
          }

          StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.section === "chat" ? 0 : root.section === "tasks" ? 1 : root.section === "notes" ? 2 : 3

            ColumnLayout {
              spacing: 12
              ListView {
                id: transcript
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true; spacing: 9
                model: messages
                delegate: Item {
                  id: messageRow
                  required property string role
                  required property string text
                  width: transcript.width
                  height: bubble.height + 6
                  Rectangle {
                    id: bubble
                    width: Math.min(transcript.width * 0.9, textItem.implicitWidth + 28)
                    height: textItem.implicitHeight + 22
                    x: messageRow.role === "user" ? transcript.width - width : 0
                    radius: 14
                    color: messageRow.role === "user" ? Qt.rgba(0.91,0.64,0.78,0.15) : Qt.rgba(1,1,1,0.045)
                    Text {
                      id: textItem
                      anchors.centerIn: parent
                      width: Math.min(transcript.width * 0.9 - 28, implicitWidth)
                      text: messageRow.text
                      wrapMode: Text.Wrap
                      color: root.textColor
                      font.pixelSize: 13
                    }
                  }
                }
              }
              RowLayout {
                Layout.fillWidth: true
                OmarchyUi.TextField {
                  id: promptField
                  Layout.fillWidth: true
                  placeholderText: "Ask Yutaro, add a task, or save a note…"
                  onAccepted: root.submitPrompt()
                }
                OmarchyUi.Button {
                  text: root.busy ? "…" : "Send"
                  foreground: "white"; accent: root.roseColor; background: "#9a6388"
                  enabled: !root.busy; focusable: true
                  onClicked: root.submitPrompt()
                }
              }
              RowLayout {
                Layout.fillWidth: true
                spacing: 7
                Repeater {
                  model: ["List tasks", "Add task", "Add note", "Physical Taby"]
                  delegate: OmarchyUi.Button {
                    required property string modelData
                    Layout.fillWidth: true
                    text: modelData; foreground: root.mutedColor; accent: root.roseColor
                    background: Qt.rgba(0.91, 0.64, 0.78, 0.075)
                    focusable: true
                    onClicked: root.quickAction(modelData)
                  }
                }
              }
              Text {
                Layout.fillWidth: true
                text: root.backend === "opencode"
                  ? "OpenCode chat may be remote/paid. Tasks and notes stay on-device."
                  : "Local Ollama keeps free-form chat on this device. Tasks and notes stay on-device."
                color: root.mutedColor; font.pixelSize: 10; wrapMode: Text.Wrap
              }
            }

            ColumnLayout {
              spacing: 10
              RowLayout {
                Layout.fillWidth: true
                OmarchyUi.TextField { id: taskField; Layout.fillWidth: true; placeholderText: "Add a local task…"; onAccepted: root.addTask() }
                OmarchyUi.Button {
                  text: "Add"; foreground: "white"; accent: root.roseColor
                  background: "#9a6388"; focusable: true; enabled: !root.busy
                  onClicked: root.addTask()
                }
              }
              ListView {
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 8
                model: taskItems
                delegate: Rectangle {
                  id: taskRow
                  required property string taskId
                  required property string title
                  required property bool done
                  width: ListView.view.width; height: 48; radius: 12
                  color: Qt.rgba(1,1,1,0.04)
                  RowLayout {
                    anchors.fill: parent; anchors.margins: 10; spacing: 8
                    Text { Layout.fillWidth: true; text: taskRow.title; color: taskRow.done ? root.mutedColor : root.textColor; font.pixelSize: 12; elide: Text.ElideRight }
                    Text { text: taskRow.done ? "DONE" : "OPEN"; color: root.roseColor; font.pixelSize: 9; font.bold: true }
                    OmarchyUi.Button {
                      text: taskRow.done ? "Reopen" : "Done"
                      foreground: root.textColor; accent: root.roseColor
                      horizontalPadding: 8; verticalPadding: 4; focusable: true
                      onClicked: root.toggleTask(taskRow.taskId, !taskRow.done)
                    }
                  }
                }
                Text {
                  anchors.centerIn: parent
                  visible: taskItems.count === 0
                  text: "A little room for what’s next. Add your first task above."
                  color: root.mutedColor
                  font.pixelSize: 12
                  wrapMode: Text.Wrap
                  width: parent.width * 0.72
                  horizontalAlignment: Text.AlignHCenter
                }
              }
              OmarchyUi.Button {
                Layout.fillWidth: true; text: "Refresh tasks"
                foreground: root.mutedColor; accent: root.roseColor; focusable: true
                onClicked: root.runBridge("tasks-list", [])
              }
            }

            ColumnLayout {
              spacing: 10
              RowLayout {
                Layout.fillWidth: true
                OmarchyUi.TextField { id: noteTitleField; Layout.fillWidth: true; placeholderText: "A short title" }
                OmarchyUi.Button {
                  text: "Save note"; foreground: "white"; accent: root.roseColor
                  background: "#9a6388"; focusable: true; enabled: !root.busy
                  onClicked: root.saveNote()
                }
              }
              TextArea {
                id: noteBodyField
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                placeholderText: "Capture a thought. This stays in your local Taby database."
                wrapMode: TextEdit.Wrap
                color: root.textColor
                selectionColor: root.roseColor
                selectedTextColor: "white"
                placeholderTextColor: root.mutedColor
                font.family: Style.font.family
                font.pixelSize: 13
                background: Rectangle {
                  radius: 12
                  color: Qt.rgba(1, 1, 1, 0.035)
                  border.color: root.borderColor
                  border.width: 1
                }
              }
              ListView {
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 8
                model: noteItems
                delegate: Rectangle {
                  id: noteRow
                  required property string noteTitle
                  required property string noteBody
                  width: ListView.view.width
                  height: noteColumn.implicitHeight + 22
                  radius: 12
                  color: Qt.rgba(1,1,1,0.04)
                  ColumnLayout {
                    id: noteColumn
                    anchors.fill: parent; anchors.margins: 11; spacing: 4
                    Text { Layout.fillWidth: true; text: noteRow.noteTitle; color: root.textColor; font.pixelSize: 12; font.bold: true; elide: Text.ElideRight }
                    Text { Layout.fillWidth: true; text: noteRow.noteBody || "(empty note)"; color: root.mutedColor; font.pixelSize: 11; wrapMode: Text.Wrap }
                  }
                }
                Text {
                  anchors.centerIn: parent
                  visible: noteItems.count === 0
                  text: "Your saved notes will appear here."
                  color: root.mutedColor; font.pixelSize: 12
                }
              }
            }

            ColumnLayout {
              spacing: 14
              Text { Layout.fillWidth: true; text: root.deviceSummary; color: root.textColor; font.pixelSize: 13; wrapMode: Text.Wrap }
              RowLayout {
                Layout.fillWidth: true
                ComboBox { id: animationPicker; Layout.fillWidth: true; model: animationItems; textRole: "name" }
                OmarchyUi.Button {
                  text: "Play"; foreground: "white"; accent: root.roseColor
                  background: "#9a6388"; focusable: true; enabled: !root.busy
                  onClicked: root.playSelectedAnimation()
                }
              }
              OmarchyUi.Button {
                Layout.fillWidth: true; text: "Scan USB device"
                foreground: root.mutedColor; accent: root.roseColor; focusable: true
                onClicked: root.runBridge("device-status", [])
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

  function saveNote() {
    var title = String(noteTitleField.text || "").trim()
    var body = String(noteBodyField.text || "").trim()
    if (root.busy || (!title && !body)) return
    root.clearNoteDraftOnSave = true
    root.runBridge("note-add", [title || "Untitled", body])
  }

  function selectBackend(value) {
    if (root.busy || (value !== "opencode" && value !== "ollama")) return
    root.backend = value
    root.backendSummary = value === "opencode" ? "OpenCode · loading models…" : "Local Ollama · loading models…"
    root.runBridge("backend-options", [value])
  }

  function selectModel(value) {
    if (root.busy || !value || value === root.modelRef) return
    root.modelRef = value
    root.runBridge("model-select", [root.backend, value])
  }

  function refreshModels() {
    if (!root.busy) root.runBridge("backend-options", [root.backend])
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
    } else if (label === "Add note") {
      root.section = "notes"
      root.runBridge("notes-list", [])
      Qt.callLater(function() { noteTitleField.forceActiveFocus() })
    } else {
      root.section = "device"
      root.runBridge("device-status", [])
    }
  }
}
