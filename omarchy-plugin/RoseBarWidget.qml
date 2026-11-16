import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "enochlawrence.rose-assistant"

  readonly property color foreground: bar ? bar.barForeground : Color.foreground
  readonly property bool showLabel: setting("showLabel", false)

  implicitWidth: contents.implicitWidth + Style.spaceReal(12)
  implicitHeight: contents.implicitHeight

  function openRose() {
    if (bar && bar.shell && typeof bar.shell.toggle === "function")
      bar.shell.toggle(moduleName, "{}")
  }

  Row {
    id: contents
    anchors.centerIn: parent
    spacing: Style.space(4)

    Text {
      text: "✿"
      color: root.foreground
      font.family: Style.font.family
      font.pixelSize: 14
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      visible: root.showLabel
      text: "Rose"
      color: root.foreground
      font.family: Style.font.family
      font.pixelSize: 12
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.openRose()
  }
}
