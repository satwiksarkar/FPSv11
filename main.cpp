#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuick3D>

#ifdef Q_OS_WIN
#include <windows.h>
#include <cstdio>
#endif
#include <QFile>
#include <QTextStream>
#include <QDateTime>

void fileLogHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg) {
    static QFile logFile;
    if (!logFile.isOpen()) {
        QString path = QCoreApplication::applicationDirPath() + QStringLiteral("/run_debug.log");
        logFile.setFileName(path);
        if (!logFile.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text)) {
            return;
        }
    }
    QTextStream out(&logFile);
    out << QDateTime::currentDateTime().toString("hh:mm:ss.zzz") << " ";
    switch (type) {
    case QtDebugMsg: out << "[DEBUG] "; break;
    case QtInfoMsg: out << "[INFO] "; break;
    case QtWarningMsg: out << "[WARNING] "; break;
    case QtCriticalMsg: out << "[CRITICAL] "; break;
    case QtFatalMsg: out << "[FATAL] "; break;
    }
    out << msg << "\n";
    if (type >= QtWarningMsg) {
        out.flush();
    }
}

int main(int argc, char *argv[])
{
    qInstallMessageHandler(fileLogHandler);
#ifdef Q_OS_WIN
    if (AttachConsole(ATTACH_PARENT_PROCESS)) {
        freopen("CONOUT$", "w", stdout);
        freopen("CONOUT$", "w", stderr);
    }
#endif
    QGuiApplication app(argc, argv);
    app.setApplicationName("FPSLabGame");
    app.setOrganizationName("CollegeLab");

    // Initialize Qt Quick 3D surface format (matches recommended settings)
    QSurfaceFormat::setDefaultFormat(QQuick3D::idealSurfaceFormat());

    QQmlApplicationEngine engine;

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.loadFromModule("FPSLabGame", "Main");

    return app.exec();
}
