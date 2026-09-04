using System.Collections.Generic;

namespace Linguist.WinUI.Models;

/// <summary>
/// 词典单词释义项模型
/// </summary>
public class WordDefinitionItem
{
    public string PartOfSpeech { get; set; } = string.Empty; // 如 "adj.", "n.", "vt."
    public string Meaning { get; set; } = string.Empty;      // 释义内容
}

/// <summary>
/// 双语对照例句模型
/// </summary>
public class ExampleSentenceItem
{
    public string English { get; set; } = string.Empty;
    public string Chinese { get; set; } = string.Empty;
}

/// <summary>
/// 翻译结果完整模型（与 Web/桌面版数据契约 1:1 对齐）
/// </summary>
public class TranslationResultModel
{
    public string Id { get; set; } = "preview-1";
    public string SourceText { get; set; } = "Efficient";
    public string TranslatedText { get; set; } = "高效的；有效率的；有能力的";
    public bool IsWord { get; set; } = true;
    public string PhoneticUs { get; set; } = "[ɪˈfɪʃnt]";
    public string PhoneticUk { get; set; } = "[ɪˈfɪʃnt]";
    public string SourceLang { get; set; } = "英语";
    public string TargetLang { get; set; } = "中文";
    public string EngineName { get; set; } = "Gemini";
    public bool IsFavorite { get; set; } = false;

    public List<WordDefinitionItem> Definitions { get; set; } = new()
    {
        new WordDefinitionItem { PartOfSpeech = "adj.", Meaning = "产生预期效果的，效率高的，有能力的" },
        new WordDefinitionItem { PartOfSpeech = "adj.", Meaning = "(机器、系统等) 节能的，高效运转的" }
    };

    public List<string> Synonyms { get; set; } = new()
    {
        "effective", "productive", "competent", "streamlined", "potent"
    };

    public List<ExampleSentenceItem> Examples { get; set; } = new()
    {
        new ExampleSentenceItem 
        { 
            English = "The new algorithm is highly efficient and responsive.", 
            Chinese = "新算法非常高效且响应迅速。" 
        },
        new ExampleSentenceItem 
        { 
            English = "An efficient use of time and system resources.", 
            Chinese = "对时间和系统资源的高效利用。" 
        }
    };
}
