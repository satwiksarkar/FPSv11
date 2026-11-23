
import QtQuick

Item {
    Component.onCompleted: {
        var ab = new ArrayBuffer(10);
        console.log('ab type:', typeof ab);
        console.log('ab.length:', ab.length);
        console.log('ab.byteLength:', ab.byteLength);
        try {
            console.log('ab.charCodeAt:', ab.charCodeAt(0));
        } catch (e) {
            console.log('Caught error:', e);
        }
        var u8 = new Uint8Array(ab);
        console.log('u8[0]:', u8[0]);
        Qt.quit();
    }
}
