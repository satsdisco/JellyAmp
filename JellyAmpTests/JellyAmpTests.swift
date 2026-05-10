//
//  JellyAmpTests.swift
//  JellyAmpTests
//
//  Created by Grafton on 10/17/25.
//

import Testing
@testable import JellyAmp

struct JellyAmpTests {

    @Test func appVersionInfoUsesBundleVersionAndBuild() async throws {
        let info = AppVersionInfo.from(infoDictionary: [
            "CFBundleShortVersionString": "1.2.3",
            "CFBundleVersion": "42"
        ])

        #expect(info.displayText == "Version 1.2.3 (42)")
    }

    @Test func appVersionInfoFallsBackWhenBundleValuesAreMissing() async throws {
        let info = AppVersionInfo.from(infoDictionary: nil)

        #expect(info.displayText == "Version ? (?)")
    }

}
