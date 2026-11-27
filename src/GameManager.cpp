#include "GameManager.h"
#include <QDebug>

GameManager::GameManager(QObject *parent)
    : QObject(parent)
    , m_gameState(GameState::MainMenu)
    , m_score(0)
    , m_difficulty(Difficulty::Easy)
    , m_totalTime(GameConfig::CAMPAIGN_MISSION_TIME)
    , m_timeRemaining(GameConfig::CAMPAIGN_MISSION_TIME)
    , m_levelEntryTime(GameConfig::CAMPAIGN_MISSION_TIME)
    , m_warningEmitted(false)
    , m_criticalEmitted(false)
    , m_gameOverReason()
{
    qDebug() << "[GameManager] Initialized in MainMenu state. Difficulty: EASY. Campaign Timer:" << m_totalTime << "s";
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

float GameManager::timeRemaining() const
{
    return m_timeRemaining;
}

float GameManager::totalTime() const
{
    return m_totalTime;
}

QString GameManager::formattedTime() const
{
    int totalSec = qMax(0, static_cast<int>(m_timeRemaining));
    int minutes = totalSec / 60;
    int seconds = totalSec % 60;
    return QStringLiteral("%1:%2")
        .arg(minutes, 2, 10, QLatin1Char('0'))
        .arg(seconds, 2, 10, QLatin1Char('0'));
}

bool GameManager::isTimeExpired() const
{
    return m_timeRemaining <= 0.0f;
}

bool GameManager::isTimerWarning() const
{
    return m_timeRemaining <= GameConfig::TIMER_WARNING_THRESHOLD && m_timeRemaining > GameConfig::TIMER_CRITICAL_THRESHOLD;
}

bool GameManager::isTimerCritical() const
{
    return m_timeRemaining <= GameConfig::TIMER_CRITICAL_THRESHOLD && m_timeRemaining > 0.0f;
}

QString GameManager::gameOverReason() const
{
    return m_gameOverReason;
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
    resetTimer();
    saveLevelEntryTime();
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
    if (m_gameOverReason.isEmpty()) {
        m_gameOverReason = QStringLiteral("SYSTEMS TERMINATED // CASUALTY REPORT CONFIRMED");
        emit gameOverReasonChanged();
    }
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
    restoreLevelEntryTime();
    setGameState(GameState::Playing);
    emit levelRestarted();
}

void GameManager::restartGame()
{
    resetScore();
    resetTimer();
    saveLevelEntryTime();
    setGameState(GameState::StoryText);
    emit gameRestarted();
    emit storyShown();
}

void GameManager::returnToMainMenu()
{
    resetScore();
    resetTimer();
    setGameState(GameState::MainMenu);
}

void GameManager::updateTimer(float deltaTime)
{
    if (m_gameState != GameState::Playing || m_timeRemaining <= 0.0f) {
        return;
    }

    float oldTime = m_timeRemaining;
    m_timeRemaining -= deltaTime;

    if (m_timeRemaining <= 0.0f) {
        m_timeRemaining = 0.0f;
        emit timeRemainingChanged();
        triggerTimeExpired();
        return;
    }

    // Check 5-minute warning threshold
    if (!m_warningEmitted && m_timeRemaining <= GameConfig::TIMER_WARNING_THRESHOLD) {
        m_warningEmitted = true;
        emit timerWarning();
    }

    // Check 1-minute critical threshold
    if (!m_criticalEmitted && m_timeRemaining <= GameConfig::TIMER_CRITICAL_THRESHOLD) {
        m_criticalEmitted = true;
        emit timerCritical();
    }

    // Emit change whenever the whole-second value changes
    if (static_cast<int>(oldTime) != static_cast<int>(m_timeRemaining)) {
        emit timeRemainingChanged();
    }
}

void GameManager::resetTimer()
{
    m_totalTime = GameConfig::CAMPAIGN_MISSION_TIME;
    m_timeRemaining = GameConfig::CAMPAIGN_MISSION_TIME;
    m_levelEntryTime = GameConfig::CAMPAIGN_MISSION_TIME;
    m_warningEmitted = false;
    m_criticalEmitted = false;
    m_gameOverReason.clear();
    emit timeRemainingChanged();
    emit gameOverReasonChanged();
}

void GameManager::setTimeRemaining(float seconds)
{
    m_timeRemaining = qBound(0.0f, seconds, m_totalTime);
    m_warningEmitted = (m_timeRemaining <= GameConfig::TIMER_WARNING_THRESHOLD);
    m_criticalEmitted = (m_timeRemaining <= GameConfig::TIMER_CRITICAL_THRESHOLD);
    emit timeRemainingChanged();
}

void GameManager::saveLevelEntryTime()
{
    m_levelEntryTime = m_timeRemaining;
    qDebug() << "[GameManager] Saved level entry time:" << formattedTime() << "(" << m_levelEntryTime << "s)";
}

void GameManager::restoreLevelEntryTime()
{
    m_timeRemaining = m_levelEntryTime;
    m_warningEmitted = (m_timeRemaining <= GameConfig::TIMER_WARNING_THRESHOLD);
    m_criticalEmitted = (m_timeRemaining <= GameConfig::TIMER_CRITICAL_THRESHOLD);
    m_gameOverReason.clear();
    qDebug() << "[GameManager] Restored level entry time:" << formattedTime() << "(" << m_timeRemaining << "s)";
    emit timeRemainingChanged();
    emit gameOverReasonChanged();
}

void GameManager::triggerTimeExpired()
{
    m_gameOverReason = QStringLiteral("MISSION TIME EXPIRED // FACILITY SELF-DESTRUCT INITIATED");
    emit gameOverReasonChanged();
    emit timeExpired();
    triggerGameOver();
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
