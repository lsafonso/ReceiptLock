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
        "CAD": CurrencyInfo(symbol: "C$", name: "Canadian Dollar", code: "CAD"),
        "AUD": CurrencyInfo(symbol: "A$", name: "Australian Dollar", code: "AUD"),
        "JPY": CurrencyInfo(symbol: "¥", name: "Japanese Yen", code: "JPY"),
        "CHF": CurrencyInfo(symbol: "CHF", name: "Swiss Franc", code: "CHF"),
        "CNY": CurrencyInfo(symbol: "¥", name: "Chinese Yuan", code: "CNY"),
        "INR": CurrencyInfo(symbol: "₹", name: "Indian Rupee", code: "INR"),
        "BRL": CurrencyInfo(symbol: "R$", name: "Brazilian Real", code: "BRL"),
        "MXN": CurrencyInfo(symbol: "MX$", name: "Mexican Peso", code: "MXN"),
        "ARS": CurrencyInfo(symbol: "AR$", name: "Argentine Peso", code: "ARS"),
        "CLP": CurrencyInfo(symbol: "CL$", name: "Chilean Peso", code: "CLP"),
        "COP": CurrencyInfo(symbol: "CO$", name: "Colombian Peso", code: "COP"),
        "PEN": CurrencyInfo(symbol: "S/", name: "Peruvian Sol", code: "PEN"),
        "VES": CurrencyInfo(symbol: "Bs", name: "Venezuelan Bolívar", code: "VES"),
        "ZAR": CurrencyInfo(symbol: "R", name: "South African Rand", code: "ZAR"),
        "EGP": CurrencyInfo(symbol: "E£", name: "Egyptian Pound", code: "EGP"),
        "NGN": CurrencyInfo(symbol: "₦", name: "Nigerian Naira", code: "NGN"),
        "KES": CurrencyInfo(symbol: "KSh", name: "Kenyan Shilling", code: "KES"),
        "MAD": CurrencyInfo(symbol: "MAD", name: "Moroccan Dirham", code: "MAD"),
        "TND": CurrencyInfo(symbol: "DT", name: "Tunisian Dinar", code: "TND"),
        "DZD": CurrencyInfo(symbol: "DA", name: "Algerian Dinar", code: "DZD"),
        "GHS": CurrencyInfo(symbol: "₵", name: "Ghanaian Cedi", code: "GHS"),
        "ETB": CurrencyInfo(symbol: "Br", name: "Ethiopian Birr", code: "ETB"),
        "UGX": CurrencyInfo(symbol: "USh", name: "Ugandan Shilling", code: "UGX"),
        "TZS": CurrencyInfo(symbol: "TSh", name: "Tanzanian Shilling", code: "TZS"),
        "RWF": CurrencyInfo(symbol: "RF", name: "Rwandan Franc", code: "RWF"),
        "XOF": CurrencyInfo(symbol: "CFA", name: "West African Franc", code: "XOF"),
        "XAF": CurrencyInfo(symbol: "FCFA", name: "Central African Franc", code: "XAF"),
        "MGA": CurrencyInfo(symbol: "Ar", name: "Malagasy Ariary", code: "MGA"),
        "MZN": CurrencyInfo(symbol: "MT", name: "Mozambican Metical", code: "MZN"),
        "ZMW": CurrencyInfo(symbol: "ZK", name: "Zambian Kwacha", code: "ZMW"),
        "ZWL": CurrencyInfo(symbol: "Z$", name: "Zimbabwean Dollar", code: "ZWL"),
        "BWP": CurrencyInfo(symbol: "P", name: "Botswana Pula", code: "BWP"),
        "NAD": CurrencyInfo(symbol: "N$", name: "Namibian Dollar", code: "NAD"),
        "SZL": CurrencyInfo(symbol: "E", name: "Swazi Lilangeni", code: "SZL"),
        "LSL": CurrencyInfo(symbol: "L", name: "Lesotho Loti", code: "LSL"),
        "MWK": CurrencyInfo(symbol: "MK", name: "Malawian Kwacha", code: "MWK"),
        "AOA": CurrencyInfo(symbol: "Kz", name: "Angolan Kwanza", code: "AOA"),
        "CDF": CurrencyInfo(symbol: "FC", name: "Congolese Franc", code: "CDF"),
        "GNF": CurrencyInfo(symbol: "FG", name: "Guinean Franc", code: "GNF"),
        "SLE": CurrencyInfo(symbol: "Le", name: "Sierra Leonean Leone", code: "SLE"),
        "LRD": CurrencyInfo(symbol: "L$", name: "Liberian Dollar", code: "LRD"),
        "GMD": CurrencyInfo(symbol: "D", name: "Gambian Dalasi", code: "GMD"),
        "CVE": CurrencyInfo(symbol: "$", name: "Cape Verdean Escudo", code: "CVE"),
        "STN": CurrencyInfo(symbol: "Db", name: "São Tomé and Príncipe Dobra", code: "STN"),
        "BIF": CurrencyInfo(symbol: "FBu", name: "Burundian Franc", code: "BIF"),
        "DJF": CurrencyInfo(symbol: "Fdj", name: "Djiboutian Franc", code: "DJF"),
        "ERN": CurrencyInfo(symbol: "Nfk", name: "Eritrean Nakfa", code: "ERN"),
        "SOS": CurrencyInfo(symbol: "S", name: "Somali Shilling", code: "SOS"),
        "SSP": CurrencyInfo(symbol: "SS£", name: "South Sudanese Pound", code: "SSP"),
        "SDG": CurrencyInfo(symbol: "SD£", name: "Sudanese Pound", code: "SDG"),
        "LYD": CurrencyInfo(symbol: "LD", name: "Libyan Dinar", code: "LYD"),
        "SEK": CurrencyInfo(symbol: "kr", name: "Swedish Krona", code: "SEK"),
        "NOK": CurrencyInfo(symbol: "kr", name: "Norwegian Krone", code: "NOK"),
        "DKK": CurrencyInfo(symbol: "kr", name: "Danish Krone", code: "DKK"),
        "PLN": CurrencyInfo(symbol: "zł", name: "Polish Złoty", code: "PLN"),
        "CZK": CurrencyInfo(symbol: "Kč", name: "Czech Koruna", code: "CZK"),
        "HUF": CurrencyInfo(symbol: "Ft", name: "Hungarian Forint", code: "HUF"),
        "RON": CurrencyInfo(symbol: "lei", name: "Romanian Leu", code: "RON"),
        "BGN": CurrencyInfo(symbol: "лв", name: "Bulgarian Lev", code: "BGN"),
        "HRK": CurrencyInfo(symbol: "kn", name: "Croatian Kuna", code: "HRK"),
        "KRW": CurrencyInfo(symbol: "₩", name: "South Korean Won", code: "KRW")
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
