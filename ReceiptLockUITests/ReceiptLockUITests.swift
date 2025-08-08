//
//  ReceiptLockUITests.swift
//  ReceiptLockUITests
//
//  Created by Leandro Afonso on 08/08/2025.
//

import XCTest

final class ReceiptLockUITests: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    func testAppLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Verify the app launches and shows the dashboard
        XCTAssertTrue(app.tabBars.buttons["Dashboard"].exists)
        XCTAssertTrue(app.tabBars.buttons["Receipts"].exists)
        XCTAssertTrue(app.tabBars.buttons["Settings"].exists)
    }
    
    func testNavigationBetweenTabs() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to Receipts tab
        app.tabBars.buttons["Receipts"].tap()
        XCTAssertTrue(app.navigationBars["Receipts"].exists)
        
        // Navigate to Settings tab
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].exists)
        
        // Navigate back to Dashboard
        app.tabBars.buttons["Dashboard"].tap()
        XCTAssertTrue(app.navigationBars["Dashboard"].exists)
    }
    
    func testAddReceiptFlow() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Tap the add button on dashboard
        app.navigationBars["Dashboard"].buttons["Add new receipt"].tap()
        
        // Verify we're in the add receipt view
        XCTAssertTrue(app.navigationBars["Add Receipt"].exists)
        
        // Fill in basic receipt information
        let titleTextField = app.textFields["Receipt title"]
        titleTextField.tap()
        titleTextField.typeText("Test Receipt")
        
        let storeTextField = app.textFields["Store name"]
        storeTextField.tap()
        storeTextField.typeText("Test Store")
        
        // Try to save (should be enabled now)
        let saveButton = app.navigationBars["Add Receipt"].buttons["Save"]
        XCTAssertTrue(saveButton.isEnabled)
        
        // Cancel instead of saving for this test
        app.navigationBars["Add Receipt"].buttons["Cancel"].tap()
        
        // Verify we're back to dashboard
        XCTAssertTrue(app.navigationBars["Dashboard"].exists)
    }
    
    func testSettingsNavigation() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to Settings
        app.tabBars.buttons["Settings"].tap()
        
        // Verify settings elements exist
        XCTAssertTrue(app.staticTexts["Notifications"].exists)
        XCTAssertTrue(app.staticTexts["Appearance"].exists)
        XCTAssertTrue(app.staticTexts["Data Management"].exists)
        XCTAssertTrue(app.staticTexts["About"].exists)
    }
}
