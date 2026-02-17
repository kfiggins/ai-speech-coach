//
//  CoachingResultTests.swift
//  SpeechCoachTests
//
//  Created by AI Speech Coach
//

import XCTest
@testable import SpeechCoach

final class CoachingResultTests: XCTestCase {

    // MARK: - Full Codable Round-Trip

    func testFullCoachingResultCodable() throws {
        let result = CoachingResult(
            scores: CoachingScores(clarity: 8, confidence: 7, conciseness: 6, structure: 9, persuasion: 5),
            metrics: CoachingMetrics(
                durationSeconds: 120.0,
                estimatedWPM: 150,
                fillerWords: ["um": 3, "uh": 2],
                repeatPhrases: ["you know", "sort of"]
            ),
            highlights: [
                CoachingHighlight(type: .strength, text: "Clear opening statement"),
                CoachingHighlight(type: .improvement, text: "Reduce filler words")
            ],
            actionPlan: ["Practice pausing instead of using filler words", "Add a stronger conclusion"],
            rewrite: CoachingRewrite(version: "improved", text: "Here is a better version..."),
            raw: nil
        )

        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(CoachingResult.self, from: data)

        XCTAssertEqual(result, decoded)
    }

    // MARK: - Scores

    func testCoachingScoresOverall() {
        let scores = CoachingScores(clarity: 8, confidence: 6, conciseness: 7, structure: 9, persuasion: 5)
        XCTAssertEqual(scores.overall, 7.0) // (8+6+7+9+5)/5 = 35/5 = 7.0
    }

    func testCoachingScoresCodable() throws {
        let scores = CoachingScores(clarity: 10, confidence: 1, conciseness: 5, structure: 5, persuasion: 5)

        let data = try JSONEncoder().encode(scores)
        let decoded = try JSONDecoder().decode(CoachingScores.self, from: data)

        XCTAssertEqual(scores, decoded)
        // overall is computed, not encoded
        XCTAssertEqual(decoded.overall, 5.2)
    }

    // MARK: - Metrics

    func testCoachingMetricsCodable() throws {
        let metrics = CoachingMetrics(
            durationSeconds: 90.5,
            estimatedWPM: 130,
            fillerWords: ["like": 5],
            repeatPhrases: ["I think"]
        )

        let data = try JSONEncoder().encode(metrics)
        let decoded = try JSONDecoder().decode(CoachingMetrics.self, from: data)

        XCTAssertEqual(metrics, decoded)
    }

    func testCoachingMetricsWithNils() throws {
        let metrics = CoachingMetrics(
            durationSeconds: nil,
            estimatedWPM: nil,
            fillerWords: nil,
            repeatPhrases: nil
        )

        let data = try JSONEncoder().encode(metrics)
        let decoded = try JSONDecoder().decode(CoachingMetrics.self, from: data)

        XCTAssertEqual(metrics, decoded)
        XCTAssertNil(decoded.durationSeconds)
        XCTAssertNil(decoded.estimatedWPM)
        XCTAssertNil(decoded.fillerWords)
        XCTAssertNil(decoded.repeatPhrases)
    }

    // MARK: - Highlights

    func testCoachingHighlightCodable() throws {
        let highlight = CoachingHighlight(type: .strength, text: "Good pacing")

        let data = try JSONEncoder().encode(highlight)
        let decoded = try JSONDecoder().decode(CoachingHighlight.self, from: data)

        XCTAssertEqual(highlight, decoded)
        XCTAssertEqual(decoded.type, .strength)
    }

    func testHighlightTypes() throws {
        let strength = CoachingHighlight(type: .strength, text: "test")
        let improvement = CoachingHighlight(type: .improvement, text: "test")

        let strengthData = try JSONEncoder().encode(strength)
        let improvementData = try JSONEncoder().encode(improvement)

        let decodedStrength = try JSONDecoder().decode(CoachingHighlight.self, from: strengthData)
        let decodedImprovement = try JSONDecoder().decode(CoachingHighlight.self, from: improvementData)

        XCTAssertEqual(decodedStrength.type, .strength)
        XCTAssertEqual(decodedImprovement.type, .improvement)
    }

    // MARK: - Rewrite

    func testCoachingRewriteCodable() throws {
        let rewrite = CoachingRewrite(version: "improved", text: "Better version of the speech")

        let data = try JSONEncoder().encode(rewrite)
        let decoded = try JSONDecoder().decode(CoachingRewrite.self, from: data)

        XCTAssertEqual(rewrite, decoded)
    }

    // MARK: - Optional Rewrite

    func testCoachingResultWithNilRewrite() throws {
        let result = CoachingResult(
            scores: CoachingScores(clarity: 5, confidence: 5, conciseness: 5, structure: 5, persuasion: 5),
            metrics: CoachingMetrics(durationSeconds: nil, estimatedWPM: nil, fillerWords: nil, repeatPhrases: nil),
            highlights: [],
            actionPlan: [],
            rewrite: nil,
            raw: nil
        )

        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(CoachingResult.self, from: data)

        XCTAssertEqual(result, decoded)
        XCTAssertNil(decoded.rewrite)
    }

    // MARK: - JSON String Decoding (simulates LLM output)

    func testDecodingFromJSONString() throws {
        let jsonString = """
        {
          "scores": {"clarity": 7, "confidence": 8, "conciseness": 6, "structure": 7, "persuasion": 8},
          "metrics": {"durationSeconds": 60, "estimatedWPM": 140, "fillerWords": {"um": 2}, "repeatPhrases": []},
          "highlights": [
            {"type": "strength", "text": "Confident delivery"},
            {"type": "improvement", "text": "Could be more concise"}
          ],
          "actionPlan": ["Cut redundant phrases", "Practice timed delivery"],
          "rewrite": {"version": "concise", "text": "A shorter version..."}
        }
        """

        let data = jsonString.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(CoachingResult.self, from: data)

        XCTAssertEqual(decoded.scores.clarity, 7)
        XCTAssertEqual(decoded.scores.confidence, 8)
        XCTAssertEqual(decoded.metrics.estimatedWPM, 140)
        XCTAssertEqual(decoded.highlights.count, 2)
        XCTAssertEqual(decoded.highlights[0].type, .strength)
        XCTAssertEqual(decoded.actionPlan.count, 2)
        XCTAssertNotNil(decoded.rewrite)
        // raw is not in the JSON, should be nil
        XCTAssertNil(decoded.raw)
    }

    // MARK: - Session Integration

    func testSessionWithCoachingResult() throws {
        var session = Session(id: "coaching-test")
        XCTAssertNil(session.coachingResult)
        XCTAssertFalse(session.hasCoaching)

        session.coachingResult = CoachingResult(
            scores: CoachingScores(clarity: 8, confidence: 7, conciseness: 6, structure: 9, persuasion: 5),
            metrics: CoachingMetrics(durationSeconds: nil, estimatedWPM: nil, fillerWords: nil, repeatPhrases: nil),
            highlights: [],
            actionPlan: [],
            rewrite: nil,
            raw: nil
        )

        XCTAssertTrue(session.hasCoaching)

        // Verify session with coaching encodes/decodes
        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(Session.self, from: data)

        XCTAssertNotNil(decoded.coachingResult)
        XCTAssertEqual(decoded.coachingResult?.scores.clarity, 8)
    }

    func testSessionWithoutCoachingBackwardCompatible() throws {
        // Simulate old session JSON without coachingResult field
        let json = """
        {
          "id": "old-session",
          "createdAt": 0,
          "durationSeconds": 30,
          "transcriptText": "Hello world",
          "stats": null
        }
        """

        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(Session.self, from: data)

        XCTAssertEqual(decoded.id, "old-session")
        XCTAssertNil(decoded.coachingResult)
        XCTAssertFalse(decoded.hasCoaching)
    }
}
