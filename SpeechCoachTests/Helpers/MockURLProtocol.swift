//
//  MockURLProtocol.swift
//  SpeechCoachTests
//
//  Shared test helpers for mocking network and keychain services
//

import Foundation
@testable import SpeechCoach

// MARK: - Mock URL Protocol

class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - Mock Keychain Service

class MockKeychainService: KeychainService {
    private var storage: [String: String] = [:]

    override func save(key: KeychainKey, value: String) throws {
        storage[key.rawValue] = value
    }

    override func retrieve(key: KeychainKey) -> String? {
        storage[key.rawValue]
    }

    override func delete(key: KeychainKey) throws {
        storage.removeValue(forKey: key.rawValue)
    }
}
