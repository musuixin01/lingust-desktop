#include "DatabaseManager.h"
#include <QSqlQuery>
#include <QSqlError>
#include <QStandardPaths>
#include <QDir>
#include <QDebug>
#include <QSet>

DatabaseManager::DatabaseManager(QObject *parent)
    : QObject(parent)
{
}

DatabaseManager::~DatabaseManager()
{
    if (m_db.isOpen()) {
        m_db.close();
    }
}

bool DatabaseManager::init()
{
    QString dataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dataPath);
    QString dbPath = dataPath + "/lingust.db";

    m_db = QSqlDatabase::addDatabase("QSQLITE");
    m_db.setDatabaseName(dbPath);

    if (!m_db.open()) {
        qWarning() << "Failed to open database:" << m_db.lastError().text();
        return false;
    }

    return createTables();
}

void DatabaseManager::setOwnerId(const QString &ownerId)
{
    const QString normalized = ownerId.trimmed();
    m_ownerId = normalized.isEmpty() ? QStringLiteral("local") : normalized.left(128);
}

bool DatabaseManager::createTables()
{
    QSqlQuery query;

    // 历史记录表
    QString createHistory = R"(
        CREATE TABLE IF NOT EXISTS history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            owner_id TEXT NOT NULL DEFAULT 'local',
            source_text TEXT NOT NULL,
            translated_text TEXT,
            source_lang TEXT,
            target_lang TEXT,
            engine TEXT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    )";
    if (!query.exec(createHistory)) {
        qWarning() << "Failed to create history table:" << query.lastError().text();
        return false;
    }

    // Additive migration for databases created before screenshot history existed.
    QSet<QString> historyColumns;
    if (query.exec("PRAGMA table_info(history)")) {
        while (query.next())
            historyColumns.insert(query.value(1).toString());
    }
    if (!historyColumns.contains("kind")
        && !query.exec("ALTER TABLE history ADD COLUMN kind TEXT DEFAULT 'text'")) {
        qWarning() << "Failed to add history kind:" << query.lastError().text();
        return false;
    }
    if (!historyColumns.contains("preview_url")
        && !query.exec("ALTER TABLE history ADD COLUMN preview_url TEXT")) {
        qWarning() << "Failed to add history preview URL:" << query.lastError().text();
        return false;
    }
    if (!historyColumns.contains("owner_id")
        && !query.exec("ALTER TABLE history ADD COLUMN owner_id TEXT NOT NULL DEFAULT 'local'")) {
        qWarning() << "Failed to add history owner:" << query.lastError().text();
        return false;
    }

    // 收藏表
    QString createFavorites = R"(
        CREATE TABLE IF NOT EXISTS favorites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            owner_id TEXT NOT NULL DEFAULT 'local',
            source_text TEXT NOT NULL,
            translated_text TEXT,
            source_lang TEXT,
            target_lang TEXT,
            phonetic TEXT,
            definitions TEXT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(owner_id, source_text)
        )
    )";
    if (!query.exec(createFavorites)) {
        qWarning() << "Failed to create favorites table:" << query.lastError().text();
        return false;
    }

    QSet<QString> favoriteColumns;
    if (query.exec("PRAGMA table_info(favorites)")) {
        while (query.next())
            favoriteColumns.insert(query.value(1).toString());
    }
    if (!favoriteColumns.contains("owner_id")) {
        if (!m_db.transaction())
            return false;
        const bool migrated = query.exec(R"(
            CREATE TABLE favorites_account_migration (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                owner_id TEXT NOT NULL DEFAULT 'local',
                source_text TEXT NOT NULL,
                translated_text TEXT,
                source_lang TEXT,
                target_lang TEXT,
                phonetic TEXT,
                definitions TEXT,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(owner_id, source_text)
            )
        )")
            && query.exec(R"(
                INSERT INTO favorites_account_migration
                    (id, owner_id, source_text, translated_text, source_lang, target_lang,
                     phonetic, definitions, timestamp)
                SELECT id, 'local', source_text, translated_text, source_lang, target_lang,
                       phonetic, definitions, timestamp FROM favorites
            )")
            && query.exec("DROP TABLE favorites")
            && query.exec("ALTER TABLE favorites_account_migration RENAME TO favorites");
        if (!migrated || !m_db.commit()) {
            m_db.rollback();
            qWarning() << "Failed to migrate favorites for account ownership:"
                       << query.lastError().text();
            return false;
        }
    }

    if (!query.exec("CREATE INDEX IF NOT EXISTS idx_history_owner_time ON history(owner_id, timestamp DESC)"))
        return false;
    if (!query.exec("CREATE INDEX IF NOT EXISTS idx_favorites_owner_time ON favorites(owner_id, timestamp DESC)"))
        return false;
    return true;
}

void DatabaseManager::addHistory(const QString &sourceText, const QString &translatedText,
                                  const QString &sourceLang, const QString &targetLang,
                                  const QString &engine, const QString &kind,
                                  const QString &previewUrl)
{
    QSqlQuery query;
    query.prepare("INSERT INTO history (owner_id, source_text, translated_text, source_lang, target_lang, engine, kind, preview_url) "
                  "VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
    query.addBindValue(m_ownerId);
    query.addBindValue(sourceText);
    query.addBindValue(translatedText);
    query.addBindValue(sourceLang);
    query.addBindValue(targetLang);
    query.addBindValue(engine);
    query.addBindValue(kind);
    query.addBindValue(previewUrl);
    query.exec();
}

QVariantList DatabaseManager::getHistory(int limit)
{
    QVariantList result;
    QSqlQuery query;
    query.prepare("SELECT id, source_text, translated_text, source_lang, target_lang, engine, timestamp, kind, preview_url "
                  "FROM history WHERE owner_id = ? ORDER BY timestamp DESC LIMIT ?");
    query.addBindValue(m_ownerId);
    query.addBindValue(limit);
    query.exec();

    while (query.next()) {
        QVariantMap item;
        item["id"] = query.value(0).toInt();
        item["sourceText"] = query.value(1).toString();
        item["translatedText"] = query.value(2).toString();
        item["sourceLang"] = query.value(3).toString();
        item["targetLang"] = query.value(4).toString();
        item["engine"] = query.value(5).toString();
        item["timestamp"] = query.value(6).toString();
        item["kind"] = query.value(7).toString().isEmpty() ? "text" : query.value(7).toString();
        item["previewUrl"] = query.value(8).toString();
        result.append(item);
    }
    return result;
}

void DatabaseManager::clearHistory()
{
    QSqlQuery query;
    query.prepare("DELETE FROM history WHERE owner_id = ?");
    query.addBindValue(m_ownerId);
    query.exec();
}

void DatabaseManager::deleteHistory(int id)
{
    QSqlQuery query;
    query.prepare("DELETE FROM history WHERE id = ? AND owner_id = ?");
    query.addBindValue(id);
    query.addBindValue(m_ownerId);
    query.exec();
}

void DatabaseManager::addFavorite(const QString &sourceText, const QString &translatedText,
                                   const QString &sourceLang, const QString &targetLang,
                                   const QString &phonetic, const QString &definitions)
{
    QSqlQuery query;
    query.prepare("INSERT INTO favorites (owner_id, source_text, translated_text, source_lang, target_lang, phonetic, definitions) "
                  "VALUES (?, ?, ?, ?, ?, ?, ?) "
                  "ON CONFLICT(owner_id, source_text) DO UPDATE SET "
                  "translated_text=excluded.translated_text, source_lang=excluded.source_lang, "
                  "target_lang=excluded.target_lang, phonetic=excluded.phonetic, "
                  "definitions=excluded.definitions, timestamp=CURRENT_TIMESTAMP");
    query.addBindValue(m_ownerId);
    query.addBindValue(sourceText);
    query.addBindValue(translatedText);
    query.addBindValue(sourceLang);
    query.addBindValue(targetLang);
    query.addBindValue(phonetic);
    query.addBindValue(definitions);
    query.exec();
}

QVariantList DatabaseManager::getFavorites()
{
    QVariantList result;
    QSqlQuery query;
    query.prepare("SELECT id, source_text, translated_text, source_lang, target_lang, phonetic, definitions, timestamp "
                  "FROM favorites WHERE owner_id = ? ORDER BY timestamp DESC");
    query.addBindValue(m_ownerId);
    query.exec();

    while (query.next()) {
        QVariantMap item;
        item["id"] = query.value(0).toInt();
        item["sourceText"] = query.value(1).toString();
        item["translatedText"] = query.value(2).toString();
        item["sourceLang"] = query.value(3).toString();
        item["targetLang"] = query.value(4).toString();
        item["phonetic"] = query.value(5).toString();
        item["definitions"] = query.value(6).toString();
        item["timestamp"] = query.value(7).toString();
        result.append(item);
    }
    return result;
}

void DatabaseManager::removeFavorite(int id)
{
    QSqlQuery query;
    query.prepare("DELETE FROM favorites WHERE id = ? AND owner_id = ?");
    query.addBindValue(id);
    query.addBindValue(m_ownerId);
    query.exec();
}

bool DatabaseManager::isFavorite(const QString &sourceText)
{
    QSqlQuery query;
    query.prepare("SELECT COUNT(*) FROM favorites WHERE source_text = ? AND owner_id = ?");
    query.addBindValue(sourceText);
    query.addBindValue(m_ownerId);
    query.exec();
    if (query.next()) {
        return query.value(0).toInt() > 0;
    }
    return false;
}
