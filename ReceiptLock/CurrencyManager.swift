//
//  CurrencyManager.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI
import Foundation

// MARK: - Currency Manager
class CurrencyManager: ObservableObject {
    static let shared = CurrencyManager()
    
    @Published var currentCurrency: String {
        didSet {
            UserDefaults.standard.set(currentCurrency, forKey: "selectedCurrency")
            objectWillChange.send()
        }
    }
    
    private let userDefaults = UserDefaults.standard
    private let currencyKey = "selectedCurrency"
    
    // Supported currencies with their symbols and formatting
    static let supportedCurrencies: [String: CurrencyInfo] = [
        "USD": CurrencyInfo(symbol: "$", name: "US Dollar", code: "USD"),
        "EUR": CurrencyInfo(symbol: "€", name: "Euro", code: "EUR"),
        "GBP": CurrencyInfo(symbol: "£", name: "British Pound", code: "GBP"),
        "BRL": CurrencyInfo(symbol: "R$", name: "Brazilian Real", code: "BRL"),
        "CHF": CurrencyInfo(symbol: "CHF", name: "Swiss Franc", code: "CHF"),
        "SEK": CurrencyInfo(symbol: "kr", name: "Swedish Krona", code: "SEK"),
        "NOK": CurrencyInfo(symbol: "kr", name: "Norwegian Krone", code: "NOK"),
        "DKK": CurrencyInfo(symbol: "kr", name: "Danish Krone", code: "DKK"),
        "PLN": CurrencyInfo(symbol: "zł", name: "Polish Złoty", code: "PLN"),
        "CZK": CurrencyInfo(symbol: "Kč", name: "Czech Koruna", code: "CZK"),
        "HUF": CurrencyInfo(symbol: "Ft", name: "Hungarian Forint", code: "HUF"),
        "RON": CurrencyInfo(symbol: "lei", name: "Romanian Leu", code: "RON"),
        "BGN": CurrencyInfo(symbol: "лв", name: "Bulgarian Lev", code: "BGN"),
        "HRK": CurrencyInfo(symbol: "kn", name: "Croatian Kuna", code: "HRK")
    ]
    
    private init() {
        // Load saved currency or default to USD
        self.currentCurrency = userDefaults.string(forKey: currencyKey) ?? "USD"
    }
    
    // MARK: - Currency Properties
    
    var currencySymbol: String {
        return CurrencyManager.supportedCurrencies[currentCurrency]?.symbol ?? "$"
    }
    
    var currencyName: String {
        return CurrencyManager.supportedCurrencies[currentCurrency]?.name ?? "US Dollar"
    }
    
    var currencyCode: String {
        return currentCurrency
    }
    
    var currencySymbolForInput: String {
        // For input fields, we might want to show the symbol differently
        return currencySymbol
    }
    
    var currencySymbolForDisplay: String {
        // For display purposes, we might want to show the symbol differently
        return currencySymbol
    }
    
    // MARK: - Formatting Methods
    
    func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currentCurrency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: price)) ?? "\(currencySymbol)\(String(format: "%.2f", price))"
    }
    
    func formatPriceWithSymbol(_ price: Double) -> String {
        return "\(currencySymbol)\(String(format: "%.2f", price))"
    }
    
    func formatPriceForDisplay(_ price: Double) -> String {
        // For display purposes, use the system currency formatter
        return price.formatted(.currency(code: currentCurrency))
    }
    
    func formatPriceForInput(_ price: Double) -> String {
        // For input fields, show just the number with currency symbol
        return "\(currencySymbol)\(String(format: "%.2f", price))"
    }
    
    // MARK: - Currency Management
    
    func changeCurrency(to currencyCode: String) {
        guard CurrencyManager.supportedCurrencies[currencyCode] != nil else {
            print("Unsupported currency: \(currencyCode)")
            return
        }
        
        currentCurrency = currencyCode
    }
    
    func getCurrencyList() -> [(String, String)] {
        return CurrencyManager.supportedCurrencies.map { (code, info) in
            (code, "\(info.symbol) \(info.name)")
        }.sorted { $0.1 < $1.1 }
    }
    
    // MARK: - Validation
    
    func isValidCurrency(_ currencyCode: String) -> Bool {
        return CurrencyManager.supportedCurrencies[currencyCode] != nil
    }
}

// MARK: - Currency Info Structure
struct CurrencyInfo {
    let symbol: String
    let name: String
    let code: String
}

// MARK: - Currency Formatting Extensions
extension Double {
    func formattedCurrency() -> String {
        return CurrencyManager.shared.formatPrice(self)
    }
    
    func formattedCurrencyWithSymbol() -> String {
        return CurrencyManager.shared.formatPriceWithSymbol(self)
    }
}

extension View {
    func currencySymbol() -> String {
        return CurrencyManager.shared.currencySymbol
    }
}
