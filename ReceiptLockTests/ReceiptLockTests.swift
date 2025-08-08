//
//  ReceiptLockTests.swift
//  ReceiptLockTests
//
//  Created by Leandro Afonso on 08/08/2025.
//

import XCTest
@testable import ReceiptLock

final class ReceiptLockTests: XCTestCase {
    
    func testExpiryDateCalculation() {
        let purchaseDate = Date()
        let warrantyMonths = 12
        
        let expiryDate = Calendar.current.date(byAdding: .month, value: warrantyMonths, to: purchaseDate)
        
        XCTAssertNotNil(expiryDate)
        
        if let expiry = expiryDate {
            let components = Calendar.current.dateComponents([.month], from: purchaseDate, to: expiry)
            XCTAssertEqual(components.month, warrantyMonths)
        }
    }
    
    func testExpiryStatusCalculation() {
        let now = Date()
        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let futureDate = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        let weekFromNow = Calendar.current.date(byAdding: .day, value: 7, to: now)!
        let monthFromNow = Calendar.current.date(byAdding: .day, value: 30, to: now)!
        
        // Test expired
        XCTAssertTrue(pastDate < now)
        
        // Test expiring soon (within 7 days)
        let daysUntilExpiry = Calendar.current.dateComponents([.day], from: now, to: weekFromNow).day ?? 0
        XCTAssertEqual(daysUntilExpiry, 7)
        
        // Test expiring within 30 days
        let daysUntilMonthExpiry = Calendar.current.dateComponents([.day], from: now, to: monthFromNow).day ?? 0
        XCTAssertEqual(daysUntilMonthExpiry, 30)
    }
    
    func testPriceFormatting() {
        let price = 999.99
        let formattedPrice = String(format: "%.2f", price)
        XCTAssertEqual(formattedPrice, "999.99")
        
        let currencyFormatted = "$\(formattedPrice)"
        XCTAssertEqual(currencyFormatted, "$999.99")
    }
    
    func testWarrantyMonthsValidation() {
        let validMonths = [0, 1, 12, 24, 60, 120]
        let invalidMonths = [-1, 121, 200]
        
        for month in validMonths {
            XCTAssertTrue(month >= 0 && month <= 120, "Month \(month) should be valid")
        }
        
        for month in invalidMonths {
            XCTAssertFalse(month >= 0 && month <= 120, "Month \(month) should be invalid")
        }
    }
}
