//
//  PermissionManagerTests.swift
//  SpeechCoachTests
//
//  Created by AI Speech Coach
//

import XCTest
@testable import SpeechCoach

final class PermissionManagerTests: XCTestCase {

    var permissionManager: PermissionManager!

    override func setUp() {
        super.setUp()
        permissionManager = PermissionManager()
    }

    override func tearDown() {
        permissionManager = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testPermissionManagerInitialization() {
        XCTAssertNotNil(permissionManager)
        XCTAssertNotNil(permissionManager.microphonePermissionStatus)
    }

    // MARK: - Permission Status Tests

    func testPermissionStatusIsGrantedProperty() {
        let granted = PermissionManager.PermissionStatus.granted
        let denied = PermissionManager.PermissionStatus.denied
        let notDetermined = PermissionManager.PermissionStatus.notDetermined
        let restricted = PermissionManager.PermissionStatus.restricted

        XCTAssertTrue(granted.isGranted)
        XCTAssertFalse(denied.isGranted)
        XCTAssertFalse(notDetermined.isGranted)
        XCTAssertFalse(restricted.isGranted)
    }

    // MARK: - Combined Permission Tests

    func testAllPermissionsGrantedWhenMicGranted() {
        permissionManager.microphonePermissionStatus = .granted
        XCTAssertTrue(permissionManager.allPermissionsGranted)
    }

    func testAllPermissionsNotGrantedWhenMicDenied() {
        permissionManager.microphonePermissionStatus = .denied
        XCTAssertFalse(permissionManager.allPermissionsGranted)
    }

    func testAllPermissionsNotGrantedWhenNotDetermined() {
        permissionManager.microphonePermissionStatus = .notDetermined
        XCTAssertFalse(permissionManager.allPermissionsGranted)
    }

    // MARK: - Note on Permission Request Tests
    // Tests that request actual system permissions are commented out
    // to avoid test failures due to permission prompts.
    // These should be tested manually or in an integration test environment.
}
