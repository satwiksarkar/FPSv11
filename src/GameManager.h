#ifndef GAMEMANAGER_H
#define GAMEMANAGER_H

#include <QObject>
#include <QString>
#include <QtQml/qqmlregistration.h>
#include "GameConfig.h"

/**
 * @brief The GameManager class manages high-level game states and scoring.
 * 
 * Central state controller for Project VANGUARD, managing transitions between
 * MainMenu, StoryText, Playing, Paused, GameOver, and Won states.
 * While in StoryText, the gameplay loop is completely halted.
 */
class GameManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    enum class GameState {
        MainMenu,
        StoryText,
        Playing,
        Paused,
        GameOver,
        Won
    };
    Q_ENUM(GameState)

    enum class Difficulty {
        Easy,
        Hard
    };
    Q_ENUM(Difficulty)

    Q_PROPERTY(GameState gameState READ gameState NOTIFY gameStateChanged)
    Q_PROPERTY(QString stateString READ stateString NOTIFY gameStateChanged)
    Q_PROPERTY(int score READ score NOTIFY scoreChanged)
    Q_PROPERTY(bool isMainMenu READ isMainMenu NOTIFY gameStateChanged)
    Q_PROPERTY(bool isPlaying READ isPlaying NOTIFY gameStateChanged)
    Q_PROPERTY(bool isStoryText READ isStoryText NOTIFY gameStateChanged)
    Q_PROPERTY(bool isPaused READ isPaused NOTIFY gameStateChanged)
    Q_PROPERTY(bool isGameOver READ isGameOver NOTIFY gameStateChanged)
    Q_PROPERTY(bool isWon READ isWon NOTIFY gameStateChanged)
    Q_PROPERTY(Difficulty difficulty READ difficulty WRITE setDifficulty NOTIFY difficultyChanged)
    Q_PROPERTY(QString difficultyName READ difficultyName NOTIFY difficultyChanged)

    // 20-Minute Campaign Mission Timer properties
    Q_PROPERTY(float timeRemaining READ timeRemaining NOTIFY timeRemainingChanged)
    Q_PROPERTY(float totalTime READ totalTime CONSTANT)
    Q_PROPERTY(QString formattedTime READ formattedTime NOTIFY timeRemainingChanged)
    Q_PROPERTY(bool isTimeExpired READ isTimeExpired NOTIFY timeRemainingChanged)
    Q_PROPERTY(bool isTimerWarning READ isTimerWarning NOTIFY timeRemainingChanged)
    Q_PROPERTY(bool isTimerCritical READ isTimerCritical NOTIFY timeRemainingChanged)
    Q_PROPERTY(QString gameOverReason READ gameOverReason NOTIFY gameOverReasonChanged)

    explicit GameManager(QObject *parent = nullptr);

    // Property getters
    GameState gameState() const;
    QString stateString() const;
    int score() const;
    bool isMainMenu() const;
    bool isPlaying() const;
    bool isStoryText() const;
    bool isPaused() const;
    bool isGameOver() const;
    bool isWon() const;
    Difficulty difficulty() const;
    QString difficultyName() const;

    // Mission Timer getters
    float timeRemaining() const;
    float totalTime() const;
    QString formattedTime() const;
    bool isTimeExpired() const;
    bool isTimerWarning() const;
    bool isTimerCritical() const;
    QString gameOverReason() const;

    // Public callable actions
    Q_INVOKABLE void startGame();
    Q_INVOKABLE void showStory();
    Q_INVOKABLE void continueFromStory();
    Q_INVOKABLE void pauseGame();
    Q_INVOKABLE void resumeGame();
    Q_INVOKABLE void togglePause();
    Q_INVOKABLE void triggerGameOver();
    Q_INVOKABLE void triggerWin();
    Q_INVOKABLE void restartCurrentLevel();
    Q_INVOKABLE void restartGame();
    Q_INVOKABLE void returnToMainMenu();
    Q_INVOKABLE void addScore(int points);
    Q_INVOKABLE void resetScore();
    Q_INVOKABLE void setDifficulty(Difficulty d);
    Q_INVOKABLE void toggleDifficulty();

    // Mission Timer actions
    Q_INVOKABLE void updateTimer(float deltaTime);
    Q_INVOKABLE void resetTimer();
    Q_INVOKABLE void setTimeRemaining(float seconds);
    Q_INVOKABLE void saveLevelEntryTime();
    Q_INVOKABLE void restoreLevelEntryTime();
    Q_INVOKABLE void triggerTimeExpired();

signals:
    void gameStateChanged();
    void scoreChanged(int newScore);
    void difficultyChanged(Difficulty d);
    void gameStarted();
    void storyShown();
    void storyContinued();
    void gamePaused();
    void gameResumed();
    void gameOver();
    void gameWon();
    void gameRestarted();
    void levelRestarted();

    // Mission Timer signals
    void timeRemainingChanged();
    void timeExpired();
    void timerWarning();
    void timerCritical();
    void gameOverReasonChanged();

private:
    void setGameState(GameState newState);

    GameState m_gameState;
    int m_score;
    Difficulty m_difficulty;

    // Mission Timer internal state
    float m_totalTime;
    float m_timeRemaining;
    float m_levelEntryTime;
    bool m_warningEmitted;
    bool m_criticalEmitted;
    QString m_gameOverReason;
};

#endif // GAMEMANAGER_H
