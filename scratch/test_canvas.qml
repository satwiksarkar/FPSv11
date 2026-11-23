
import QtQuick

Item {
    width: 200
    height: 200

    property var mapBytes: null

    Component.onCompleted: {
        var ab = new ArrayBuffer(6400); // 80x80
        var u8 = new Uint8Array(ab);
        for (var i = 0; i < 6400; ++i) u8[i] = (i % 2 === 0) ? 1 : 0;
        mapBytes = u8;
        console.log('mapBytes length:', mapBytes.length, 'tile 0:', mapBytes[0]);
        canvas.requestPaint();
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            var ctx = getContext('2d');
            ctx.clearRect(0, 0, width, height);
            console.log('Painting canvas! mapBytes is:', mapBytes !== null);
            var w = 80;
            var h = 80;
            var tileW = width / w;
            var tileH = height / h;
            for (var r = 0; r < 5; ++r) {
                for (var c = 0; c < 5; ++c) {
                    var tile = mapBytes[r * w + c];
                    ctx.fillStyle = (tile === 1) ? '#3e5c76' : '#141d26';
                    ctx.fillRect(c * tileW, r * tileH, tileW, tileH);
                }
            }
            console.log('Canvas painting SUCCESS!');
            Qt.quit();
        }
    }
}
