#ifndef GAMEMANAGER_H
#define GAMEMANAGER_H

#include <QObject>
#include <QString>
#include <QtQml/qqmlregistration.h>

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

private:
    void setGameState(GameState newState);

    GameState m_gameState;
    int m_score;
    Difficulty m_difficulty;
};

#endif // GAMEMANAGER_H
