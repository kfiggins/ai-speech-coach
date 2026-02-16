//
//  StatsService.swift
//  SpeechCoach
//
//  Created by AI Speech Coach
//

import Foundation

/// Service responsible for analyzing transcript text and computing statistics
class StatsService {

    // MARK: - Properties

    private var stopWords: Set<String> = []
    private var fillerWordsSingle: Set<String> = []
    private var fillerWordsMulti: [String] = []

    // MARK: - Initialization

    init() {
        loadStopWords()
        loadFillerWords()
    }

    // MARK: - Stats Calculation

    /// Calculate statistics for a given transcript
    func calculateStats(transcript: String, duration: TimeInterval?) -> SessionStats {
        // Tokenize the transcript
        let tokens = tokenize(transcript: transcript)

        // Calculate basic counts
        let totalWords = tokens.count
        let uniqueWords = Set(tokens).count

        // Calculate filler words
        let (fillerCount, fillerBreakdown) = countFillerWords(in: transcript)

        // Calculate most used words (excluding stop words and filler words)
        let topWords = findTopWords(tokens: tokens, limit: 10)

        // Calculate words per minute
        let wordsPerMinute = calculateWordsPerMinute(wordCount: totalWords, duration: duration)

        return SessionStats(
            totalWords: totalWords,
            uniqueWords: uniqueWords,
            fillerWordCount: fillerCount,
            fillerWordBreakdown: fillerBreakdown,
            topWords: topWords,
            wordsPerMinute: wordsPerMinute
        )
    }

    // MARK: - Tokenization

    /// Tokenize transcript into words
    private func tokenize(transcript: String) -> [String] {
        // Normalize to lowercase
        let normalized = transcript.lowercased()

        // Remove punctuation but keep apostrophes and hyphens
        let allowedCharacters = CharacterSet.alphanumerics
            .union(CharacterSet.whitespaces)
            .union(CharacterSet(charactersIn: "'-"))

        let filtered = normalized.unicodeScalars.filter { allowedCharacters.contains($0) }
        let cleanedText = String(String.UnicodeScalarView(filtered))

        // Split into words and filter empty strings
        let tokens = cleanedText
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "-'")) }
            .filter { !$0.isEmpty }

        return tokens
    }

    // MARK: - Filler Word Detection

    /// Count filler words in the transcript
    private func countFillerWords(in transcript: String) -> (count: Int, breakdown: [String: Int]) {
        let normalized = transcript.lowercased()
        var breakdown: [String: Int] = [:]
        var totalCount = 0

        // Count multi-word fillers first (to avoid double-counting)
        for multiWord in fillerWordsMulti {
            let pattern = "\\b" + NSRegularExpression.escapedPattern(for: multiWord) + "\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: normalized, range: NSRange(normalized.startIndex..., in: normalized))
                let count = matches.count
                if count > 0 {
                    breakdown[multiWord] = count
                    totalCount += count
                }
            }
        }

        // Count single-word fillers
        let tokens = tokenize(transcript: transcript)
        for token in tokens {
            if fillerWordsSingle.contains(token) {
                breakdown[token, default: 0] += 1
                totalCount += 1
            }
        }

        return (totalCount, breakdown)
    }

    // MARK: - Top Words

    /// Find the most frequently used words (excluding stop words and filler words)
    private func findTopWords(tokens: [String], limit: Int) -> [WordCount] {
        // Filter out stop words and filler words
        let meaningfulTokens = tokens.filter { token in
            !stopWords.contains(token) && !fillerWordsSingle.contains(token)
        }

        // Count occurrences
        var wordCounts: [String: Int] = [:]
        for token in meaningfulTokens {
            wordCounts[token, default: 0] += 1
        }

        // Sort by count and take top N
        let sortedWords = wordCounts
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { WordCount(word: $0.key, count: $0.value) }

        return Array(sortedWords)
    }

    // MARK: - Words Per Minute

    /// Calculate words per minute
    private func calculateWordsPerMinute(wordCount: Int, duration: TimeInterval?) -> Double? {
        guard let duration = duration, duration > 0 else {
            return nil
        }

        let minutes = duration / 60.0
        return Double(wordCount) / minutes
    }

    // MARK: - Configuration Loading

    /// Load stop words from JSON file
    private func loadStopWords() {
        // Use Bundle.module for SPM
        let bundle = Bundle.module

        guard let url = bundle.url(forResource: "stop-words", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let words = try? JSONDecoder().decode([String].self, from: data) else {
            print("Warning: Could not load stop-words.json, using empty set")
            return
        }

        stopWords = Set(words)
    }

    /// Load filler words from JSON file
    private func loadFillerWords() {
        // Use Bundle.module for SPM
        let bundle = Bundle.module

        guard let url = bundle.url(forResource: "filler-words", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Warning: Could not load filler-words.json, using empty set")
            return
        }

        struct FillerWords: Codable {
            let single: [String]
            let multi: [String]
        }

        guard let fillerWords = try? JSONDecoder().decode(FillerWords.self, from: data) else {
            print("Warning: Could not decode filler-words.json")
            return
        }

        fillerWordsSingle = Set(fillerWords.single)
        fillerWordsMulti = fillerWords.multi.sorted { $0.count > $1.count } // Sort by length (longest first)
    }
}
