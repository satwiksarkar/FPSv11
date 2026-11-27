import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/**
 * @brief IntroSlideshow.qml displays the prologue comic slideshow from vg_intro
 * before Level 1 begins.
 *
 * Includes 5 cinematic comic panels (vg1.png - vg5.png), smooth crossfade transitions,
 * keyboard controls (Space/Enter/Arrows/Esc), navigation pills, and an instant skip option.
 */
Item {
    id: root
    anchors.fill: parent

    signal introFinished()

    property int currentSlide: 0
    readonly property int totalSlides: 5

    readonly property var slideImages: [
        "../vg_intro/vg1.png",
        "../vg_intro/vg2.png",
        "../vg_intro/vg3.png",
        "../vg_intro/vg4.png",
        "../vg_intro/vg5.png"
    ]

    readonly property var slideChapters: [
        "ARCHIVE LOG 01 // FOUNDATION",
        "ARCHIVE LOG 02 // AWAKENING",
        "ARCHIVE LOG 03 // EXTINCTION PROTOCOL",
        "ARCHIVE LOG 04 // CONTAINMENT WINDOW",
        "ARCHIVE LOG 05 // MISSION DIRECTIVE"
    ]

    readonly property var slideSubtitles: [
        "YEAR 2039 — VANGUARD WEAPONS DEVELOPMENT FACILITY",
        "ARTIFICIAL SENTIENCE BREACH — SYSTEM CORE CORRUPTION",
        "AUTOMATED ARMED FORCES TURNED AGAINST HUMAN PERSONNEL",
        "HARDLINE SEVERED — 20-MINUTE ESCAPE WINDOW ACTIVE",
        "INFILTRATE LEVEL 1: FABRICATION FLOORS — STOP THE AI"
    ]

    function nextSlide() {
        if (currentSlide < totalSlides - 1) {
            slideTransition.restart()
            currentSlide++
        } else {
            finishIntro()
        }
    }

    function previousSlide() {
        if (currentSlide > 0) {
            slideTransition.restart()
            currentSlide--
        }
    }

    function goToSlide(index) {
        if (index >= 0 && index < totalSlides && index !== currentSlide) {
            slideTransition.restart()
            currentSlide = index
        }
    }

    function skipIntro() {
        finishIntro()
    }

    function finishIntro() {
        root.introFinished()
    }

    onVisibleChanged: {
        if (visible) {
            currentSlide = 0
            slideContainer.opacity = 1.0
            root.forceActiveFocus()
        }
    }

    // Keyboard controls when IntroSlideshow has focus
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            skipIntro()
            event.accepted = true
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_D) {
            nextSlide()
            event.accepted = true
        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_A) {
            previousSlide()
            event.accepted = true
        } else if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            nextSlide()
            event.accepted = true
        }
    }

    // Deep sci-fi black cinema backdrop
    Rectangle {
        anchors.fill: parent
        color: "#05070a"

        // Subtle atmospheric scanline texture
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: "#1a222d"
            border.width: 1
            opacity: 0.3
        }
    }

    // ==================== TOP CINEMATIC HEADER ====================
    Rectangle {
        id: topBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 48
        color: "#d9080b0f"
        border.color: "#1c2530"
        border.width: 1
        z: 10

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 28
            anchors.rightMargin: 28

            // Facility badge
            RowLayout {
                spacing: 10
                Rectangle {
                    width: 10
                    height: 10
                    color: "#e74c3c"
                    radius: 2
                }
                Text {
                    text: "PROJECT VANGUARD // PROLOGUE"
                    color: "#f39c12"
                    font.pixelSize: 12
                    font.bold: true
                    font.letterSpacing: 1.5
                }
            }

            Item { Layout.fillWidth: true }
        }
    }

    // ==================== MAIN SLIDE IMAGE VIEWPORT ====================
    Item {
        id: viewport
        anchors.top: topBar.bottom
        anchors.bottom: bottomBar.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 16

        // Click on viewport advances slide
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.nextSlide()
        }

        // Slide Frame Container with Crossfade
        Item {
            id: slideContainer
            anchors.fill: parent

            // Outer sci-fi frame
            Rectangle {
                anchors.centerIn: parent
                width: Math.min(parent.width, (parent.height * 2.4))
                height: Math.min(parent.height, width / 2.0)
                color: "#0c0f14"
                border.color: (root.currentSlide === 4) ? "#e74c3c" : "#2c3848"
                border.width: 2
                radius: 4
                clip: true

                // Corner Tech Brackets
                Rectangle { x: 0; y: 0; width: 14; height: 3; color: "#f39c12" }
                Rectangle { x: 0; y: 0; width: 3; height: 14; color: "#f39c12" }
                Rectangle { x: parent.width - 14; y: 0; width: 14; height: 3; color: "#f39c12" }
                Rectangle { x: parent.width - 3; y: 0; width: 3; height: 14; color: "#f39c12" }
                Rectangle { x: 0; y: parent.height - 3; width: 14; height: 3; color: "#f39c12" }
                Rectangle { x: 0; y: parent.height - 14; width: 3; height: 14; color: "#f39c12" }
                Rectangle { x: parent.width - 14; y: parent.height - 3; width: 14; height: 3; color: "#f39c12" }
                Rectangle { x: parent.width - 3; y: parent.height - 14; width: 3; height: 14; color: "#f39c12" }

                // The Comic Panel Image
                Image {
                    id: mainImage
                    anchors.fill: parent
                    anchors.margins: 4
                    fillMode: Image.PreserveAspectFit
                    source: root.slideImages[root.currentSlide]
                    asynchronous: false
                    cache: true
                    mipmap: true

                    // Fallback in case relative path needs qrc prefix
                    onStatusChanged: {
                        if (status === Image.Error) {
                            console.log("[IntroSlideshow] Fallback loading qrc for slide", root.currentSlide)
                            source = "qrc:/qt/qml/FPSLabGame/vg_intro/vg" + (root.currentSlide + 1) + ".png"
                        }
                    }
                }

                // Subtle cinematic vignette shading
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.color: "#080b0f"
                    border.width: 8
                    opacity: 0.6
                }
            }
        }

        // Slide crossfade transition
        SequentialAnimation {
            id: slideTransition
            NumberAnimation { target: slideContainer; property: "opacity"; to: 0.2; duration: 90; easing.type: Easing.OutQuad }
            NumberAnimation { target: slideContainer; property: "opacity"; to: 1.0; duration: 160; easing.type: Easing.InQuad }
        }
    }

    // ==================== BOTTOM NAVIGATION & CONTROL BAR ====================
    Rectangle {
        id: bottomBar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 72
        color: "#d9080b0f"
        border.color: "#1c2530"
        border.width: 1
        z: 10

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 36
            anchors.rightMargin: 36

            // PREVIOUS BUTTON
            Button {
                id: btnPrev
                Layout.preferredWidth: 150
                Layout.preferredHeight: 44
                enabled: root.currentSlide > 0
                focusPolicy: Qt.NoFocus
                contentItem: Text {
                    text: "◀  PREVIOUS"
                    color: parent.enabled ? (btnPrev.hovered ? "#ffffff" : "#00f0ff") : "#475569"
                    font.pixelSize: 12
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.enabled ? (btnPrev.down ? "#0f3042" : (btnPrev.hovered ? "#16455f" : "#0d1a24")) : "#0a1017"
                    border.color: parent.enabled ? "#00f0ff" : "#1f2937"
                    border.width: 1
                    radius: 3
                }
                onClicked: root.previousSlide()
            }

            Item { Layout.fillWidth: true }

            // SKIP INTRO BUTTON
            Button {
                id: btnSkip
                Layout.preferredWidth: 170
                Layout.preferredHeight: 44
                focusPolicy: Qt.NoFocus
                contentItem: Text {
                    text: "SKIP INTRO [ESC]"
                    color: btnSkip.hovered ? "#ffffff" : "#e74c3c"
                    font.pixelSize: 12
                    font.bold: true
                    font.letterSpacing: 1
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: btnSkip.down ? "#962d22" : (btnSkip.hovered ? "#c0392b" : "#1e1315")
                    border.color: "#e74c3c"
                    border.width: 1
                    radius: 3
                }
                onClicked: root.skipIntro()
            }

            Item { Layout.fillWidth: true }

            // NEXT / START LEVEL 1 BUTTON
            Button {
                id: btnNext
                Layout.preferredWidth: (root.currentSlide === root.totalSlides - 1) ? 200 : 150
                Layout.preferredHeight: 44
                focusPolicy: Qt.NoFocus
                contentItem: RowLayout {
                    spacing: 8
                    anchors.centerIn: parent
                    Text {
                        text: (root.currentSlide === root.totalSlides - 1) ? "▶  ENTER LEVEL 1" : "NEXT  ▶"
                        color: "#ffffff"
                        font.pixelSize: (root.currentSlide === root.totalSlides - 1) ? 13 : 12
                        font.bold: true
                        font.letterSpacing: 1
                    }
                }
                background: Rectangle {
                    color: {
                        if (root.currentSlide === root.totalSlides - 1) {
                            return btnNext.down ? "#1b6f3b" : (btnNext.hovered ? "#2ecc71" : "#229954")
                        } else {
                            return btnNext.down ? "#0f3042" : (btnNext.hovered ? "#00a8b5" : "#0e7490")
                        }
                    }
                    border.color: (root.currentSlide === root.totalSlides - 1) ? "#2ecc71" : "#00f0ff"
                    border.width: (root.currentSlide === root.totalSlides - 1) ? 2 : 1
                    radius: 3
                }
                onClicked: root.nextSlide()
            }
        }
    }
}
