import XCTest

@MainActor
final class ScreenFlowTests: XCTestCase {
    func testMainCalendarSettingsMigrationFlow() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"]
        app.launch()
        defer { app.terminate() }
        tap(app.buttons["daily.calendar"], afterCapture: "01-main")
        tap(app.buttons["calendar.returnToDiary"], afterCapture: "02-calendar")
        tap(app.buttons["daily.settings"])
        tap(app.buttons["settings.migrate"], afterCapture: "03-settings")
        tap(app.buttons["기록 보내기"], afterCapture: "04-migration-confirm")
        let result = app.staticTexts["기록 3개를 서버에서 확인했어요. 기기의 원본은 유지돼요."]
        XCTAssertTrue(result.waitForExistence(timeout: 10))
        capture("05-migration-complete")
    }

    func testMockLoginFlow() {
        let app = makeApp(arguments: ["--ui-login"])
        defer { app.terminate() }
        tap(app.buttons["login.apple"], afterCapture: "06-login-mock")
        XCTAssertTrue(app.buttons["daily.calendar"].waitForExistence(timeout: 10))
        capture("07-login-main")
    }

    func testMigrationFailureRetryFlow() {
        let app = makeApp(arguments: ["--ui-migration-failure"])
        defer { app.terminate() }
        openMigration(app)
        XCTAssertTrue(app.staticTexts["테스트 연결이 끊겼어요. 다시 시도해 주세요."].waitForExistence(timeout: 10))
        capture("08-migration-failed")
        tap(app.buttons["settings.migrate"])
        tap(app.buttons["기록 보내기"], afterCapture: "09-migration-retry-confirm")
        XCTAssertTrue(app.staticTexts["기록 3개를 서버에서 확인했어요. 기기의 원본은 유지돼요."].waitForExistence(timeout: 10))
        capture("10-migration-retry-complete")
    }

    func testMigrationProgressCancelFlow() {
        let app = makeApp(arguments: ["--ui-migration-slow"])
        defer { app.terminate() }
        openMigration(app)
        XCTAssertTrue(app.staticTexts["1 / 3개 확인 완료"].waitForExistence(timeout: 10))
        tap(app.buttons["migration.cancel"], afterCapture: "11-migration-progress")
        XCTAssertTrue(app.staticTexts["전송을 중단했어요. 다시 시작하면 완료한 기록은 건너뛰어요."].waitForExistence(timeout: 10))
        capture("12-migration-cancelled")
        XCTAssertTrue(app.buttons["settings.migrate"].isEnabled)
    }

    func testCreateDetailEditFlow() throws {
        let app = makeApp(arguments: ["--ui-record"])
        defer { app.terminate() }
        tap(app.buttons["record.create"], afterCapture: "13-workout")
        tap(app.buttons["diary.next"], afterCapture: "14-create-fitness")
        tap(app.buttons["diary.shoe.ui-test-shoe"])
        tap(app.buttons["diary.next"], afterCapture: "15-create-shoes")
        tap(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "diary.style.")).firstMatch)
        tap(app.buttons["diary.next"], afterCapture: "16-create-style")
        tap(app.buttons["diary.next"], afterCapture: "17-create-pain")
        let difficulty = app.otherElements["diary.difficulty"]
        XCTAssertTrue(difficulty.waitForExistence(timeout: 10))
        difficulty.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        tap(app.buttons["diary.next"], afterCapture: "18-create-difficulty")
        let memo = app.textViews["diary.memo"]
        tap(memo)
        memo.typeText("UI flow original")
        app.buttons["완료"].tap()
        tap(app.buttons["diary.save"], afterCapture: "19-create-memo")
        tap(app.buttons["record.edit"], afterCapture: "20-record-detail")
        for _ in 0..<5 { tap(app.buttons["diary.next"]) }
        XCTAssertEqual(app.textViews["diary.memo"].value as? String, "UI flow original")
        tap(app.textViews["diary.memo"])
        app.textViews["diary.memo"].typeText(" updated")
        let expectedUpdatedMemo = try XCTUnwrap(app.textViews["diary.memo"].value as? String)
        XCTAssertNotEqual(expectedUpdatedMemo, "UI flow original")
        XCTAssertTrue(expectedUpdatedMemo.contains("updated"))
        app.buttons["완료"].tap()
        tap(app.buttons["diary.save"], afterCapture: "21-edit-memo")
        XCTAssertTrue(app.buttons["record.edit"].waitForExistence(timeout: 10))
        app.swipeUp()
        XCTAssertTrue(app.staticTexts[expectedUpdatedMemo].waitForExistence(timeout: 10))
        capture("22-record-updated")
    }

    private func makeApp(arguments: [String]) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"] + arguments
        app.launch()
        return app
    }

    private func openMigration(_ app: XCUIApplication) {
        tap(app.buttons["daily.settings"])
        tap(app.buttons["settings.migrate"])
        tap(app.buttons["기록 보내기"])
    }

    private func tap(_ element: XCUIElement, afterCapture name: String? = nil) {
        XCTAssertTrue(element.waitForExistence(timeout: 15), "화면 이동 대상 없음: \(element)")
        let hittable = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "hittable == true"), object: element
        )
        XCTAssertEqual(XCTWaiter.wait(for: [hittable], timeout: 10), .completed)
        if let name { capture(name) }
        element.tap()
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
