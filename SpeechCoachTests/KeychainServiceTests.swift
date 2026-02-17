//
//  KeychainServiceTests.swift
//  SpeechCoachTests
//
//  Created by AI Speech Coach
//

import XCTest
@testable import SpeechCoach

final class KeychainServiceTests: XCTestCase {

    var keychain: MockKeychainService!

    override func setUp() async throws {
        try await super.setUp()
        keychain = MockKeychainService()
    }

    override func tearDown() async throws {
        keychain = nil
        try await super.tearDown()
    }

    func testSaveAndRetrieve() throws {
        try keychain.save(key: .openAIAPIKey, value: "sk-test-123")
        let retrieved = keychain.retrieve(key: .openAIAPIKey)
        XCTAssertEqual(retrieved, "sk-test-123")
    }

    func testRetrieveNonexistent() {
        let value = keychain.retrieve(key: .openAIAPIKey)
        XCTAssertNil(value)
    }

    func testDelete() throws {
        try keychain.save(key: .openAIAPIKey, value: "sk-test-456")
        try keychain.delete(key: .openAIAPIKey)
        XCTAssertNil(keychain.retrieve(key: .openAIAPIKey))
    }

    func testDeleteNonexistentDoesNotThrow() {
        XCTAssertNoThrow(try keychain.delete(key: .openAIAPIKey))
    }

    func testOverwrite() throws {
        try keychain.save(key: .openAIAPIKey, value: "sk-first")
        try keychain.save(key: .openAIAPIKey, value: "sk-second")
        XCTAssertEqual(keychain.retrieve(key: .openAIAPIKey), "sk-second")
    }

    func testHasOpenAIKey() throws {
        XCTAssertFalse(keychain.hasOpenAIKey)
        try keychain.save(key: .openAIAPIKey, value: "sk-test")
        XCTAssertTrue(keychain.hasOpenAIKey)
    }
}
