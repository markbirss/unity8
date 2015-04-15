/*
 * Copyright (C) 2013,2014 Canonical, Ltd.
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

#ifndef DIRECTIONAL_DRAG_AREA_H
#define DIRECTIONAL_DRAG_AREA_H

#include <QtQuick/QQuickItem>
#include "UbuntuGesturesQmlGlobal.h"
#include "Damper.h"
#include "Direction.h"

// lib UbuntuGestures
#include <Pool.h>
#include <Timer.h>

class TouchOwnershipEvent;
class UnownedTouchEvent;
class DirectionalDragAreaPrivate;

/*
 An area that detects axis-aligned single-finger drag gestures

 If a drag deviates too much from the components' direction recognition will
 fail. It will also fail if the drag or flick is too short. E.g. a noisy or
 fidgety click

 See doc/DirectionalDragArea.svg
 */
class UBUNTUGESTURESQML_EXPORT DirectionalDragArea : public QQuickItem {
    Q_OBJECT

    // The direction in which the gesture should move in order to be recognized.
    Q_PROPERTY(Direction::Type direction READ direction WRITE setDirection NOTIFY directionChanged)

    // The distance travelled by the finger along the axis specified by
    // DirectionalDragArea's direction.
    Q_PROPERTY(qreal distance READ distance NOTIFY distanceChanged)

    // The distance travelled by the finger along the axis specified by
    // DirectionalDragArea's direction in scene coordinates
    Q_PROPERTY(qreal sceneDistance READ sceneDistance NOTIFY sceneDistanceChanged)

    // Position of the touch point performing the drag relative to this item.
    Q_PROPERTY(qreal touchX READ touchX NOTIFY touchXChanged)
    Q_PROPERTY(qreal touchY READ touchY NOTIFY touchYChanged)

    // Position of the touch point performing the drag, in scene's coordinate system
    Q_PROPERTY(qreal touchSceneX READ touchSceneX NOTIFY touchSceneXChanged)
    Q_PROPERTY(qreal touchSceneY READ touchSceneY NOTIFY touchSceneYChanged)

    // Whether a drag gesture is taking place
    Q_PROPERTY(bool dragging READ dragging NOTIFY draggingChanged)

    // Whether a gesture should be Recognized as soon a touch lands on the area.
    // With this property enabled it will work pretty much like a MultiPointTouchArea,
    // just with a different API.
    //
    // It's false by default. In most cases you will not want that enabled.
    Q_PROPERTY(bool immediateRecognition
            READ immediateRecognition
            WRITE setImmediateRecognition
            NOTIFY immediateRecognitionChanged)

    Q_ENUMS(Direction)
public:
    DirectionalDragArea(QQuickItem *parent = 0);

    Direction::Type direction() const;
    void setDirection(Direction::Type);

    qreal distance() const;
    qreal sceneDistance() const;

    qreal touchX() const;
    qreal touchY() const;

    qreal touchSceneX() const;
    qreal touchSceneY() const;

    bool dragging() const;

    bool immediateRecognition() const;
    void setImmediateRecognition(bool enabled);

    bool event(QEvent *e) override;

Q_SIGNALS:
    void directionChanged(Direction::Type direction);
    void draggingChanged(bool value);
    void distanceChanged(qreal value);
    void sceneDistanceChanged(qreal value);
    void touchXChanged(qreal value);
    void touchYChanged(qreal value);
    void touchSceneXChanged(qreal value);
    void touchSceneYChanged(qreal value);
    void immediateRecognitionChanged(bool value);

protected:
    virtual void touchEvent(QTouchEvent *event);
    virtual void itemChange(ItemChange change, const ItemChangeData &value);

public: // so tests can access it
    DirectionalDragAreaPrivate *d;
};

#endif // DIRECTIONAL_DRAG_AREA_H
