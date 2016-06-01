/*
 * Copyright (C) 2014-2015 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors: Michael Zanetti <michael.zanetti@canonical.com>
 */

import QtQuick 2.4
import Ubuntu.Components 1.3
import Unity.Application 0.1

FocusScope {
    id: root

    implicitWidth: applicationWindow.width
    implicitHeight: (decorationShown ? decoration.height : 0) + applicationWindow.implicitHeight

    property alias application: applicationWindow.application
    property alias surface: applicationWindow.surface
    property alias active: decoration.active
    readonly property alias title: applicationWindow.title
    property alias fullscreen: applicationWindow.fullscreen

    // Whether we want it to sho in general
    property bool showDecoration: true
    // Whether it is actually shown. Even if showDecoration is true, this might be false for other reasons (e.g. app is fullscreened)
    readonly property bool decorationShown: showDecoration && !fullscreen
    property bool highlightShown: false
    property real shadowOpacity: 1

    property alias resizeSurface: applicationWindow.resizeSurface
    property alias requestedWidth: applicationWindow.requestedWidth
    property alias requestedHeight: applicationWindow.requestedHeight

    property alias minimumWidth: applicationWindow.minimumWidth
    readonly property int minimumHeight: (root.decorationShown ? decoration.height : 0) + applicationWindow.minimumHeight
    property alias maximumWidth: applicationWindow.maximumWidth
    readonly property int maximumHeight: (root.decorationShown ? decoration.height : 0) + applicationWindow.maximumHeight
    property alias widthIncrement: applicationWindow.widthIncrement
    property alias heightIncrement: applicationWindow.heightIncrement

    signal close()
    signal maximize()
    signal minimize()
    signal decorationPressed()

    Rectangle {
        id: selectionHighlight
        anchors.fill: parent
        anchors.margins: -units.gu(1)
        color: "white"
        opacity: highlightShown ? 0.15 : 0
    }

    Rectangle {
        anchors { left: selectionHighlight.left; right: selectionHighlight.right; bottom: selectionHighlight.bottom; }
        height: units.dp(2)
        color: UbuntuColors.orange
        visible: highlightShown
    }

    BorderImage {
        anchors {
            fill: root
            margins: active ? -units.gu(2) : -units.gu(1.5)
        }
        source: "graphics/dropshadow2gu.sci"
        opacity: root.shadowOpacity * .3
        visible: !fullscreen
    }

    WindowDecoration {
        id: decoration
        target: root.parent
        objectName: "appWindowDecoration"
        anchors { left: parent.left; top: parent.top; right: parent.right }
        height: units.gu(3)
        width: root.width
        title: applicationWindow.title
        visible: root.decorationShown

        onClose: root.close();
        onMaximize: { root.decorationPressed(); root.maximize(); }
        onMinimize: root.minimize();
        onPressed: root.decorationPressed();
    }

    ApplicationWindow {
        id: applicationWindow
        objectName: "appWindow"
        anchors.top: parent.top
        anchors.topMargin: root.decorationShown ? decoration.height : 0
        anchors.left: parent.left
        width: root.width
        height: root.height - anchors.topMargin
        requestedHeight: root.requestedHeight
        interactive: true
        focus: true
    }
}
