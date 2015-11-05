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
 */

import QtQuick 2.4
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.1
import Unity.Application 0.1
import "../Components"
import "../Components/PanelState"
import Utils 0.1
import Ubuntu.Gestures 0.1
import GlobalShortcut 1.0

Rectangle {
    id: root
    anchors.fill: parent

    // Controls to be set from outside
    property int dragAreaWidth // just to comply with the interface shared between stages
    property real maximizedAppTopMargin
    property bool interactive
    property bool spreadEnabled // just to comply with the interface shared between stages
    property real inverseProgress: 0 // just to comply with the interface shared between stages
    property int shellOrientationAngle: 0
    property int shellOrientation
    property int shellPrimaryOrientation
    property int nativeOrientation
    property bool beingResized: false
    property bool keepDashRunning: true
    property bool suspended: false
    property alias background: wallpaper.source
    property alias altTabPressed: spread.altTabPressed

    // functions to be called from outside
    function updateFocusedAppOrientation() { /* TODO */ }
    function updateFocusedAppOrientationAnimated() { /* TODO */}

    // To be read from outside
    readonly property var mainApp: ApplicationManager.focusedApplicationId
            ? ApplicationManager.findApplication(ApplicationManager.focusedApplicationId)
            : null
    property int mainAppWindowOrientationAngle: 0
    readonly property bool orientationChangesEnabled: false

    Connections {
        target: ApplicationManager
        onApplicationAdded: {
            if (spread.state == "altTab") {
                spread.state = "";
            }

            ApplicationManager.focusApplication(appId);
        }

        onApplicationRemoved: {
            priv.focusNext();
        }

        onFocusRequested: {
            var appIndex = priv.indexOf(appId);
            var appDelegate = appRepeater.itemAt(appIndex);
            appDelegate.restoreFromMinimized();

            if (spread.state == "altTab") {
                spread.cancel();
            }
        }
    }

    GlobalShortcut {
        id: closeWindowShortcut
        shortcut: Qt.AltModifier|Qt.Key_F4
        onTriggered: ApplicationManager.stopApplication(priv.focusedAppId)
        active: priv.focusedAppId !== ""
    }

    GlobalShortcut {
        id: showSpreadShortcut
        shortcut: Qt.MetaModifier|Qt.Key_W
        onTriggered: spread.state = "altTab"
    }

    GlobalShortcut {
        id: minimizeAllShortcut
        shortcut: Qt.MetaModifier|Qt.ControlModifier|Qt.Key_D
        onTriggered: priv.minimizeAllWindows()
    }

    GlobalShortcut {
        id: maximizeWindowShortcut
        shortcut: Qt.MetaModifier|Qt.ControlModifier|Qt.Key_Up
        onTriggered: priv.focusedAppDelegate.maximize()
        active: priv.focusedAppDelegate !== null
    }

    GlobalShortcut {
        id: maximizeWindowLeftShortcut
        shortcut: Qt.MetaModifier|Qt.ControlModifier|Qt.Key_Left
        onTriggered: priv.focusedAppDelegate.maximizeLeft()
        active: priv.focusedAppDelegate !== null
    }

    GlobalShortcut {
        id: maximizeWindowRightShortcut
        shortcut: Qt.MetaModifier|Qt.ControlModifier|Qt.Key_Right
        onTriggered: priv.focusedAppDelegate.maximizeRight()
        active: priv.focusedAppDelegate !== null
    }

    GlobalShortcut {
        id: minimizeRestoreShortcut
        shortcut: Qt.MetaModifier|Qt.ControlModifier|Qt.Key_Down
        onTriggered: priv.focusedAppDelegate.maximized || priv.focusedAppDelegate.maximizedLeft || priv.focusedAppDelegate.maximizedRight
                     ? priv.focusedAppDelegate.restore() : priv.focusedAppDelegate.minimize(true)
        active: priv.focusedAppDelegate !== null
    }

    QtObject {
        id: priv

        readonly property string focusedAppId: ApplicationManager.focusedApplicationId
        readonly property var focusedAppDelegate: {
            var index = indexOf(focusedAppId);
            return index >= 0 && index < appRepeater.count ? appRepeater.itemAt(index) : null
        }

        function indexOf(appId) {
            for (var i = 0; i < ApplicationManager.count; i++) {
                if (ApplicationManager.get(i).appId == appId) {
                    return i;
                }
            }
            return -1;
        }

        function minimizeAllWindows() {
            for (var i = 0; i < appRepeater.count; i++) {
                var appDelegate = appRepeater.itemAt(i);
                if (appDelegate && !appDelegate.minimized) {
                    appDelegate.minimize(false); // minimize but don't switch focus
                }
            }

            ApplicationManager.unfocusCurrentApplication(); // no app should have focus at this point
        }

        function focusNext() {
            ApplicationManager.unfocusCurrentApplication();
            for (var i = 0; i < appRepeater.count; i++) {
                var appDelegate = appRepeater.itemAt(i);
                if (appDelegate && !appDelegate.minimized) {
                    ApplicationManager.focusApplication(appDelegate.appId);
                    return;
                }
            }
        }

        function isAnyMaximized() {
            for (var i = 0; i < appRepeater.count; i++) {
                var appDelegate = appRepeater.itemAt(i);
                if (appDelegate && appDelegate.maximized) {
                    return true;
                }
            }
            return false;
        }
    }

    Connections {
        target: PanelState
        onClose: {
            ApplicationManager.stopApplication(ApplicationManager.focusedApplicationId)
        }
        onMinimize: appRepeater.itemAt(0).minimize(true);
        onMaximize: priv.focusedAppDelegate // don't restore minimized apps when double clicking the panel
                    && priv.focusedAppDelegate.restore();
    }

    Binding {
        target: PanelState
        property: "buttonsVisible"
        value: priv.focusedAppDelegate !== null && priv.focusedAppDelegate.maximized // FIXME for LIM
    }

    Binding {
        target: PanelState
        property: "title"
        value: {
            if (priv.focusedAppDelegate !== null) {
                if (priv.focusedAppDelegate.maximized)
                    return priv.focusedAppDelegate.title
                else
                    return priv.focusedAppDelegate.appName
            }
            return ""
        }
        when: priv.focusedAppDelegate
    }

    Binding {
        target: PanelState
        property: "dropShadow"
        value: priv.focusedAppDelegate && !priv.focusedAppDelegate.maximized && priv.isAnyMaximized()
    }

    Component.onDestruction: PanelState.buttonsVisible = false;

    FocusScope {
        id: appContainer
        objectName: "appContainer"
        anchors.fill: parent
        focus: spread.state !== "altTab"

        CrossFadeImage {
            id: wallpaper
            anchors.fill: parent
            sourceSize { height: root.height; width: root.width }
            fillMode: Image.PreserveAspectCrop
        }

        Repeater {
            id: appRepeater
            model: ApplicationManager
            objectName: "appRepeater"

            delegate: FocusScope {
                id: appDelegate
                objectName: "appDelegate_" + appId
                z: ApplicationManager.count - index
                y: units.gu(3)
                width: units.gu(60)
                height: units.gu(50)
                focus: appId === priv.focusedAppId

                property bool maximized: false
                property bool maximizedLeft: false
                property bool maximizedRight: false
                property bool minimized: false
                readonly property string appId: model.appId
                property bool animationsEnabled: true
                property alias title: decoratedWindow.title
                readonly property string appName: model.name

                onFocusChanged: {
                    if (focus && ApplicationManager.focusedApplicationId !== appId) {
                        ApplicationManager.focusApplication(appId);
                    }
                }

                Binding {
                    target: ApplicationManager.get(index)
                    property: "requestedState"
                    // TODO: figure out some lifecycle policy, like suspending minimized apps
                    //       if running on a tablet or something.
                    // TODO: If the device has a dozen suspended apps because it was running
                    //       in staged mode, when it switches to Windowed mode it will suddenly
                    //       resume all those apps at once. We might want to avoid that.
                    value: ApplicationInfoInterface.RequestedRunning // Always running for now
                }

                function maximize(animated) {
                    animationsEnabled = (animated === undefined) || animated;
                    minimized = false;
                    maximized = true;
                    maximizedLeft = false;
                    maximizedRight = false;
                }
                function maximizeLeft() {
                    minimized = false;
                    maximized = false;
                    maximizedLeft = true;
                    maximizedRight = false;
                }
                function maximizeRight() {
                    minimized = false;
                    maximized = false;
                    maximizedLeft = false;
                    maximizedRight = true;
                }
                function minimize(animated) {
                    animationsEnabled = (animated === undefined) || animated;
                    minimized = true;
                }
                function restore(animated) {
                    animationsEnabled = (animated === undefined) || animated;
                    minimized = false;
                    maximized = false;
                    maximizedLeft = false;
                    maximizedRight = false;
                }
                function restoreFromMinimized(animated) {
                    animationsEnabled = (animated === undefined) || animated;
                    minimized = false;
                    if (maximized)
                        maximize();
                    else if (maximizedLeft)
                        maximizeLeft();
                    else if (maximizedRight)
                        maximizeRight();
                    ApplicationManager.focusApplication(appId);
                }

                states: [
                    State {
                        name: "normal"; when: !appDelegate.maximized && !appDelegate.minimized
                                              && !appDelegate.maximizedLeft && !appDelegate.maximizedRight
                    },
                    State {
                        name: "maximized"; when: appDelegate.maximized && !appDelegate.minimized
                        PropertyChanges { target: appDelegate; x: 0; y: 0; width: root.width; height: root.height }
                    },
                    State {
                        name: "maximizedLeft"; when: appDelegate.maximizedLeft && !appDelegate.minimized
                        PropertyChanges { target: appDelegate; x: 0; y: units.gu(3); width: root.width/2; height: root.height - units.gu(3) }
                    },
                    State {
                        name: "maximizedRight"; when: appDelegate.maximizedRight && !appDelegate.minimized
                        PropertyChanges { target: appDelegate; x: root.width/2; y: units.gu(3); width: root.width/2; height: root.height - units.gu(3) }
                    },
                    State {
                        name: "minimized"; when: appDelegate.minimized
                        PropertyChanges { target: appDelegate; x: -appDelegate.width / 2; scale: units.gu(5) / appDelegate.width; opacity: 0 }
                    }
                ]
                transitions: [
                    Transition {
                        from: "maximized,maximizedLeft,maximizedRight,minimized,normal,"
                        to: "maximized,maximizedLeft,maximizedRight,minimized,normal,"
                        enabled: appDelegate.animationsEnabled
                        SequentialAnimation {
                            PropertyAnimation { target: appDelegate; properties: "x,y,opacity,width,height,scale" }
                            ScriptAction {
                                script: {
                                    if (animationsEnabled && state === "minimized" ) {
                                        priv.focusNext();
                                    }
                                }
                            }
                        }
                    },
                    Transition {
                        from: ""
                        to: "altTab"
                        PropertyAction { target: appDelegate; properties: "y,angle,z,itemScale,itemScaleOriginY" }
                        PropertyAction { target: decoratedWindow; properties: "anchors.topMargin" }
                        PropertyAnimation {
                            target: appDelegate; properties: "x"
                            from: root.width
                            duration: rightEdgePushArea.containsMouse ? UbuntuAnimation.FastDuration :0
                            easing: UbuntuAnimation.StandardEasing
                        }
                    }
                ]

                Binding {
                    id: previewBinding
                    target: appDelegate
                    property: "z"
                    value: ApplicationManager.count + 1
                    when: index == spread.highlightedIndex && blurLayer.ready
                }

                WindowResizeArea {
                    target: appDelegate
                    minWidth: units.gu(10)
                    minHeight: units.gu(10)
                    borderThickness: units.gu(2)
                    windowId: model.appId // FIXME: Change this to point to windowId once we have such a thing

                    onPressed: { ApplicationManager.focusApplication(model.appId) }
                }

                DecoratedWindow {
                    id: decoratedWindow
                    objectName: "decoratedWindow"
                    anchors.left: appDelegate.left
                    anchors.top: appDelegate.top
                    width: appDelegate.width
                    height: appDelegate.height
                    application: ApplicationManager.get(index)
                    active: ApplicationManager.focusedApplicationId === model.appId
                    focus: true

                    onClose: ApplicationManager.stopApplication(model.appId)
                    onMaximize: appDelegate.maximized || appDelegate.maximizedLeft || appDelegate.maximizedRight
                                ? appDelegate.restore() : appDelegate.maximize()
                    onMinimize: appDelegate.minimize(true)
                    onDecorationPressed: { ApplicationManager.focusApplication(model.appId) }
                }
            }
        }
    }

    BlurLayer {
        id: blurLayer
        anchors.fill: parent
        source: appContainer
        visible: false
    }

    Rectangle {
        id: spreadBackground
        anchors.fill: parent
        color: "#55000000"
        visible: false
    }

    MouseArea {
        id: eventEater
        anchors.fill: parent
        visible: spreadBackground.visible
        enabled: visible
    }

    DesktopSpread {
        id: spread
        objectName: "spread"
        anchors.fill: parent
        workspace: appContainer
        focus: state == "altTab"
    }
}
