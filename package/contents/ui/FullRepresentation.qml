import QtQuick 2.15
import QtQml.XmlListModel
import QtQuick.Controls

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

Item {
  id: window
  width: 300
  height: 500

  property var url: plasmoid.configuration.url
  property string feedTitle: plasmoid.configuration.title || ""
  property int refresh: 1000 * plasmoid.configuration.refresh
  property var headerColor: plasmoid.configuration.headerColor
  property var listOpacity: plasmoid.configuration.listOpacity
  property var titleSize: plasmoid.configuration.titleSize
  property var descriptionSize: plasmoid.configuration.descriptionSize

  function stripString (str) {
    var regex = /(<img.*?>)/gi;
    str = str.replace(regex, "");
    regex = /&#228;/gi;
    str = str.replace(regex, "ä");
    regex = /&#246;/gi;
    str = str.replace(regex, "ö");
    regex = /&#252;/gi;
    str = str.replace(regex, "ü");
    regex = /&#196;/gi;
    str = str.replace(regex, "Ä");
    regex = /&#214;/gi;
    str = str.replace(regex, "Ö");
    regex = /&#220;/gi;
    str = str.replace(regex, "Ü");
    regex = /&#223;/gi;
    str = str.replace(regex, "ß");

    return str;
  }

  XmlListModel {
    id: xmlModel
    source: url
    query: "/rss/channel/item"

    XmlListModelRole { name: "title"; elementName: "title" }
    XmlListModelRole { name: "pubDate"; elementName: "pubDate" }
    XmlListModelRole { name: "description"; elementName: "description" }
    XmlListModelRole { name: "link"; elementName: "link" }

    onStatusChanged: busyIndicator.isBusy = true
  }

  Component {
    id: feedDelegate
    Rectangle {
      height: layout.height
      width: thefeed.width
      color: "white"
      Component.onCompleted: busyIndicator.isBusy = false


      Item {
        height: layout.height
        width: thefeed.width

        Column {
          id: layout
          padding: 10
          Rectangle {
            width: thefeed.width - 20
            height: 4
            color: headerColor
          }
          Row {
            topPadding: titleSize / 2 - 5
            bottomPadding: titleSize / 2
            Text {
              width: thefeed.width - 20
              wrapMode: Text.WordWrap
              font.pixelSize: titleSize
              color: '#00003c'
              font.bold: true
              text: title
              horizontalAlignment: Text.AlignHCenter
            }
          }
          Rectangle {
            width: thefeed.width - 20
            height: 4
            color: headerColor
          }
          Row {
            Text {
              width: thefeed.width - 20
              wrapMode: Text.WordWrap
              font.pixelSize: descriptionSize
              color: "black"
              font.bold: false
              text: stripString(description)
              linkColor: "#000066"
            }
          }
        }

        MouseArea {
          acceptedButtons: Qt.LeftButton
          anchors.fill: parent
          onClicked: {
            Qt.openUrlExternally(link)
          }
        }
      }
    }
  }

  ListView {
    id: thefeed
    opacity: listOpacity / 100
    maximumFlickVelocity: 2500
    clip: true
    width: parent.width
    anchors.fill: parent
    spacing: 2
    model: xmlModel
    delegate: feedDelegate
  }

  Item {
    id: busyIndicator
    property bool isBusy: true
    property var animate: plasmoid.configuration.animateBusyIndicator

    onAnimateChanged: updateIndicator()
    onIsBusyChanged: updateIndicator()

    anchors.centerIn: parent

    function updateIndicator() {
      animated.running = isBusy && animate
      icon.visible = isBusy && !animate
    }

    BusyIndicator {
      id: animated
      running: isBusy && animate
      anchors.centerIn: parent
    }
  }

  Timer {
    id: refreshTimer
    interval: refresh
    running: true
    repeat: true
    onTriggered: { xmlModel.reload() }
  }

  Plasmoid.contextualActions: [
    PlasmaCore.Action {
      text: i18n("Refresh")
      icon.name: "view-refresh"
      onTriggered: xmlModel.reload()
    }
  ]
}
