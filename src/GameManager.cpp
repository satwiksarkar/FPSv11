#include "GameManager.h"
#include <QDebug>

GameManager::GameManager(QObject *parent)
    : QObject(parent)
    , m_gameState(GameState::MainMenu)
    , m_score(0)
    , m_difficulty(Difficulty::Easy)
{
    qDebug() << "[GameManager] Initialized in MainMenu state. Difficulty: EASY";
}

GameManager::GameState GameManager::gameState() const
{
    return m_gameState;
}

QString GameManager::stateString() const
{
    switch (m_gameState) {
    case GameState::MainMenu:  return QStringLiteral("MainMenu");
    case GameState::StoryText: return QStringLiteral("StoryText");
    case GameState::Playing:   return QStringLiteral("Playing");
    case GameState::Paused:    return QStringLiteral("Paused");
    case GameState::GameOver:  return QStringLiteral("GameOver");
    case GameState::Won:       return QStringLiteral("Won");
    }
    return QStringLiteral("Unknown");
}

int GameManager::score() const
{
    return m_score;
}

bool GameManager::isMainMenu() const
{
    return m_gameState == GameState::MainMenu;
}

bool GameManager::isPlaying() const
{
    return m_gameState == GameState::Playing;
}

bool GameManager::isStoryText() const
{
    return m_gameState == GameState::StoryText;
}

bool GameManager::isPaused() const
{
    return m_gameState == GameState::Paused;
}

bool GameManager::isGameOver() const
{
    return m_gameState == GameState::GameOver;
}

bool GameManager::isWon() const
{
    return m_gameState == GameState::Won;
}

void GameManager::setGameState(GameState newState)
{
    if (m_gameState != newState) {
        m_gameState = newState;
        qDebug() << "[GameManager] State changed to:" << stateString();
        emit gameStateChanged();
    }
}

void GameManager::startGame()
{
    resetScore();
    // Before Level 1, start with StoryText (intro mission briefing)
    setGameState(GameState::StoryText);
    emit gameStarted();
    emit storyShown();
}

void GameManager::showStory()
{
    setGameState(GameState::StoryText);
    emit storyShown();
}

void GameManager::continueFromStory()
{
    if (m_gameState == GameState::StoryText) {
        setGameState(GameState::Playing);
        emit storyContinued();
    }
}

void GameManager::pauseGame()
{
    if (m_gameState == GameState::Playing) {
        setGameState(GameState::Paused);
        emit gamePaused();
    }
}

void GameManager::resumeGame()
{
    if (m_gameState == GameState::Paused) {
        setGameState(GameState::Playing);
        emit gameResumed();
    }
}

void GameManager::togglePause()
{
    if (m_gameState == GameState::Playing) {
        pauseGame();
    } else if (m_gameState == GameState::Paused) {
        resumeGame();
    }
}

void GameManager::triggerGameOver()
{
    setGameState(GameState::GameOver);
    emit gameOver();
}

void GameManager::triggerWin()
{
    setGameState(GameState::Won);
    emit gameWon();
}

void GameManager::restartCurrentLevel()
{
    setGameState(GameState::Playing);
    emit levelRestarted();
}

void GameManager::restartGame()
{
    resetScore();
    setGameState(GameState::StoryText);
    emit gameRestarted();
    emit storyShown();
}

void GameManager::returnToMainMenu()
{
    resetScore();
    setGameState(GameState::MainMenu);
}

void GameManager::addScore(int points)
{
    if (points > 0) {
        m_score += points;
        emit scoreChanged(m_score);
    }
}

void GameManager::resetScore()
{
    if (m_score != 0) {
        m_score = 0;
        emit scoreChanged(m_score);
    }
}

GameManager::Difficulty GameManager::difficulty() const
{
    return m_difficulty;
}

QString GameManager::difficultyName() const
{
    return (m_difficulty == Difficulty::Easy) ? QStringLiteral("EASY") : QStringLiteral("HARD");
}

void GameManager::setDifficulty(Difficulty d)
{
    if (m_difficulty != d) {
        m_difficulty = d;
        qDebug() << "[GameManager] Difficulty set to:" << difficultyName();
        emit difficultyChanged(m_difficulty);
    }
}

void GameManager::toggleDifficulty()
{
    setDifficulty(m_difficulty == Difficulty::Easy ? Difficulty::Hard : Difficulty::Easy);
}
