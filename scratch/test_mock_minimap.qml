
import QtQuick

Rectangle {
    id: root
    width: 200
    height: 200
    color: '#0c1017'

    property var mapBytes: null
    property var exploredTiles: null
    property int mapW: 80
    property int mapH: 80

    Component.onCompleted: {
        var ab = new ArrayBuffer(80 * 80);
        var u8 = new Uint8Array(ab);
        for (var r = 0; r < 80; ++r) {
            for (var c = 0; c < 80; ++c) {
                var isWall = (r === 0 || r === 79 || c === 0 || c === 79 || (r % 10 === 0 && c < 40));
                u8[r * 80 + c] = isWall ? 1 : 0;
            }
        }
        mapBytes = u8;
        exploredTiles = new Uint8Array(80 * 80);
        for (var i = 0; i < 80 * 80; ++i) {
            exploredTiles[i] = (i % 3 === 0) ? 1 : 0;
        }
        canvas.requestPaint();
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            var ctx = getContext('2d');
            ctx.clearRect(0, 0, width, height);
            var w = root.mapW;
            var h = root.mapH;
            var tileW = width / w;
            var tileH = height / h;

            for (var r = 0; r < h; ++r) {
                var rOffset = r * w;
                var y = r * tileH;
                for (var c = 0; c < w; ++c) {
                    var idx = rOffset + c;
                    var tile = mapBytes[idx];
                    var isExplored = (root.exploredTiles[idx] > 0);
                    if (tile === 1) {
                        ctx.fillStyle = isExplored ? '#4a6984' : '#2d4255';
                    } else {
                        ctx.fillStyle = isExplored ? '#1b2838' : '#121a24';
                    }
                    ctx.fillRect(c * tileW, y, Math.ceil(tileW), Math.ceil(tileH));
                }
            }
            console.log('Canvas successfully painted complete 80x80 layout without error!');
            Qt.quit();
        }
    }
}
