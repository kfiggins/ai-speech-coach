//
//  StatsServiceTests.swift
//  SpeechCoachTests
//
//  Created by AI Speech Coach
//

import XCTest
@testable import SpeechCoach

final class StatsServiceTests: XCTestCase {

    var statsService: StatsService!

    override func setUp() {
        super.setUp()
        statsService = StatsService()
    }

    override func tearDown() {
        statsService = nil
        super.tearDown()
    }

    // MARK: - Basic Stats Tests

    func testCalculateStatsWithEmptyTranscript() {
        let stats = statsService.calculateStats(transcript: "", duration: nil)

        XCTAssertEqual(stats.totalWords, 0)
        XCTAssertEqual(stats.uniqueWords, 0)
        XCTAssertEqual(stats.fillerWordCount, 0)
        XCTAssertTrue(stats.topWords.isEmpty)
        XCTAssertNil(stats.wordsPerMinute)
    }

    func testCalculateStatsWithSimpleTranscript() {
        let transcript = "Hello world. This is a test."
        let stats = statsService.calculateStats(transcript: transcript, duration: nil)

        XCTAssertEqual(stats.totalWords, 6)
        // "hello", "world", "this", "is", "a", "test"
        // After stop word removal: "hello", "world", "test" (unique: 3)
        XCTAssertGreaterThan(stats.uniqueWords, 0)
        XCTAssertEqual(stats.fillerWordCount, 0)
    }

    func testTotalWordCount() {
        let transcript = "The quick brown fox jumps over the lazy dog."
        let stats = statsService.calculateStats(transcript: transcript, duration: nil)

        XCTAssertEqual(stats.totalWords, 9)
    }

    func testUniqueWordCount() {
        let transcript = "Hello hello world world world."
        let stats = statsService.calculateStats(transcript: transcript, duration: nil)

        XCTAssertEqual(stats.totalWords, 5)
        XCTAssertEqual(stats.uniqueWords, 2) // "hello" and "world"
    }

    // MARK: - Filler Word Detection Tests

    func testDetectSingleWordFillers() {
        let transcript = "Um, I think, uh, we should, like, totally do this."
        let stats = statsService.calculateStats(transcript: transcript, duration: nil)

        XCTAssertGreaterThan(stats.fillerWordCount, 0)
        XCTAssertFalse(stats.fillerWordBreakdown.isEmpty)

        // Should detect "um", "uh", "like", "totally"
        XCTAssertTrue(stats.fillerWordBreakdown["um"] ?? 0 > 0)
        XCTAssertTrue(stats.fillerWordBreakdown["uh"] ?? 0 > 0)
        XCTAssertTrue(stats.fillerWordBreakdown["like"] ?? 0 > 0)
    }

    func testDetectMultiWordFillers() {
        let transcript = "I mean, you know, we should do this, you know what I mean?"
        let stats = statsService.calculateStats(transcript: transcript, duration: nil)

        XCTAssertGreaterThan(stats.fillerWordCount, 0)
        // Should detect "i mean" and "you know"
        XCTAssertTrue(stats.fillerWordBreakdown["i mean"] ?? 0 > 0)
        XCTAssertTrue(stats.fillerWordBreakdown["you know"] ?? 0 > 0)
    }

    func testFillerWordBreakdown() {
        let transcript = "Um, like, um, uh, like, like."
        let stats = statsService.calculateStats(transcript: transcript, duration: nil)

        XCTAssertEqual(stats.fillerWordCount, 6)
        XCTAssertEqual(stats.fillerWordBreakdown["um"], 2)
        XCTAssertEqual(stats.fillerWordBreakdown["like"], 3)
        XCTAssertEqual(stats.fillerWordBreakdown["uh"], 1)
    }

    // MARK: - Top Words Tests

    func testTopWordsExcludeStopWords() {
        let transcript = "The cat sat on the mat. The cat was happy."
        let stats = statsService.calculateStats(transcript: transcript, duration: nil)

        // "cat" appears twice, "sat", "mat", "happy" appear once
        // Stop words like "the", "on", "was" should be excluded
        let topWordStrings = stats.topWords.map { $0.word }
        XCTAssertFalse(topWordStrings.contains("the"))
        XCTAssertFalse(topWordStrings.contains("on"))
        XCTAssertFalse(topWordStrings.contains("was"))
        XCTAssertTrue(topWordStrings.contains("cat"))
    }

    func testTopWordsSortedByFrequency() {
        let transcript = "apple banana apple cherry apple banana apple."
        let stats = statsService.calculateStats(transcript: transcript, duration: nil)

        XCTAssertFalse(stats.topWords.isEmpty)

        // "apple" should be first (4 times)
        if let firstWord = stats.topWords.first {
            XCTAssertEqual(firstWord.word, "apple")
            XCTAssertEqual(firstWord.count, 4)
        }

        // "banana" should be second (2 times)
        if stats.topWords.count > 1 {
            XCTAssertEqual(stats.topWords[1].word, "banana")
            XCTAssertEqual(stats.topWords[1].count, 2)
        }
    }

    func testTopWordsLimit() {
        // Create a transcript with many unique words
        let words = (1...20).map { "word\($0)" }
        let transcript = words.joined(separator: " ")
        let stats = statsService.calculateStats(transcript: transcript, duration: nil)

        // Should return at most 10 words
        XCTAssertLessThanOrEqual(stats.topWords.count, 10)
    }

    // MARK: - Words Per Minute Tests

    func testWordsPerMinuteCalculation() {
        let transcript = String(repeating: "word ", count: 120)
        let duration: TimeInterval = 60.0 // 1 minute
        let stats = statsService.calculateStats(transcript: transcript, duration: duration)

        XCTAssertNotNil(stats.wordsPerMinute)
        if let wpm = stats.wordsPerMinute {
            XCTAssertEqual(wpm, 120.0, accuracy: 0.1)
        }
    }

    func testWordsPerMinuteWithNoDuration() {
        let transcript = "Some words here."
        let stats = statsService.calculateStats(transcript: transcript, duration: nil)

        XCTAssertNil(stats.wordsPerMinute)
    }

    func testWordsPerMinuteWithZeroDuration() {
        let transcript = "Some words here."
        let stats = statsService.calculateStats(transcript: transcript, duration: 0)

        XCTAssertNil(stats.wordsPerMinute)
    }

    func testWordsPerMinuteWithShortDuration() {
        let transcript = "Hello world this is a test of words per minute."
        let duration: TimeInterval = 30.0 // 30 seconds
        let stats = statsService.calculateStats(transcript: transcript, duration: duration)

        XCTAssertNotNil(stats.wordsPerMinute)
        if let wpm = stats.wordsPerMinute {
            // 10 words in 0.5 minutes = 20 WPM
            XCTAssertEqual(wpm, 20.0, accuracy: 1.0)
        }
    }

    // MARK: - Tokenization Tests

    func testTokenizationRemovesPunctuation() {
        let transcript = "Hello, world! How are you? I'm fine."
        let stats = statsService.calculateStats(transcript: transcript, duration: nil)

        // Should have: hello, world, how, are, you, i'm, fine (stop words removed for top words)
        XCTAssertEqual(stats.totalWords, 7)
    }

    func testTokenizationHandlesApostrophes() {
        let transcript = "I'm don't can't won't."
        let stats = statsService.calculateStats(transcript: transcript, duration: nil)

        // Should preserve contractions
        XCTAssertGreaterThan(stats.totalWords, 0)
    }

    func testTokenizationNormalizesCase() {
        let transcript = "Hello HELLO hello HeLLo."
        let stats = statsService.calculateStats(transcript: transcript, duration: nil)

        XCTAssertEqual(stats.totalWords, 4)
        XCTAssertEqual(stats.uniqueWords, 1) // All should be normalized to "hello"
    }

    // MARK: - Edge Cases

    func testTranscriptWithOnlyStopWords() {
        let transcript = "the a an and or but if of to in."
        let stats = statsService.calculateStats(transcript: transcript, duration: nil)

        XCTAssertGreaterThan(stats.totalWords, 0)
        // Top words should be empty since all are stop words
        XCTAssertTrue(stats.topWords.isEmpty)
    }

    func testTranscriptWithOnlyFillerWords() {
        let transcript = "um uh like literally um uh."
        let stats = statsService.calculateStats(transcript: transcript, duration: nil)

        XCTAssertEqual(stats.totalWords, 6)
        XCTAssertEqual(stats.fillerWordCount, 6)
        // Top words should be empty since all are filler words
        XCTAssertTrue(stats.topWords.isEmpty)
    }

    func testTranscriptWithNumbers() {
        let transcript = "I have 3 apples and 5 oranges making 8 fruits."
        let stats = statsService.calculateStats(transcript: transcript, duration: nil)

        XCTAssertGreaterThan(stats.totalWords, 0)
        // Should handle numbers as words
        XCTAssertTrue(stats.topWords.contains { $0.word == "apples" || $0.word == "oranges" || $0.word == "fruits" })
    }

    func testLongTranscript() {
        // Test with a longer, more realistic transcript
        let transcript = """
        So, um, I think we should, like, really focus on the main objectives here.
        You know, the project has been, uh, going well, but we need to, sort of,
        accelerate the timeline. I mean, we have resources available, and, you know,
        the team is ready. So, basically, let's just move forward with confidence.
        """
        let stats = statsService.calculateStats(transcript: transcript, duration: 60.0)

        XCTAssertGreaterThan(stats.totalWords, 40)
        XCTAssertGreaterThan(stats.uniqueWords, 20)
        XCTAssertGreaterThan(stats.fillerWordCount, 5)
        XCTAssertFalse(stats.topWords.isEmpty)
        XCTAssertNotNil(stats.wordsPerMinute)
    }
}
