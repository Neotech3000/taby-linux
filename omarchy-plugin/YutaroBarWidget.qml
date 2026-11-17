import QtQuick
import qs.Commons
import qs.Ui as OmarchyUi

OmarchyUi.BarWidget {
  id: root
  moduleName: "enochlawrence.yutaro-assistant"

  readonly property color foreground: bar ? bar.barForeground : Color.foreground
  readonly property bool showLabel: setting("showLabel", false)

  implicitWidth: launcher.implicitWidth
  implicitHeight: launcher.implicitHeight

  function openYutaro() {
    if (bar && bar.shell && typeof bar.shell.toggle === "function")
      bar.shell.toggle(moduleName, "{}")
  }

  OmarchyUi.WidgetButton {
    id: launcher
    anchors.fill: parent
    bar: root.bar
    text: root.showLabel ? "✿  Yutaro" : "✿"
    foreground: root.foreground
    fontSize: root.showLabel ? 12 : 16
    tooltipText: "Open Yutaro assistant"
    onPressed: function(button) {
      if (button === Qt.LeftButton) root.openYutaro()
    }
  }
}
