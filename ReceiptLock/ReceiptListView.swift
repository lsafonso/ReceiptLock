//
//  ReceiptListView.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI
import CoreData

struct ReceiptListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Receipt.createdAt, ascending: false)],
        animation: .default)
    private var receipts: FetchedResults<Receipt>
    
    @State private var searchText = ""
    @State private var selectedFilter: ReceiptFilter = .all
    @State private var showingAddReceipt = false
    @State private var animateFilters = false
    
    enum ReceiptFilter: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case expired = "Expired"
        case expiringSoon = "Expiring Soon"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .active: return "checkmark.circle.fill"
            case .expired: return "exclamationmark.triangle.fill"
            case .expiringSoon: return "clock.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return AppTheme.primary
            case .active: return AppTheme.success
            case .expired: return AppTheme.error
            case .expiringSoon: return AppTheme.warning
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppTheme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filter Picker
                    filterPicker
                    
                    // Receipt List
                    if filteredReceipts.isEmpty {
                        emptyStateView
                    } else {
                        receiptList
                    }
                }
            }
            .navigationTitle("Receipts")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search receipts...")
        }
        .sheet(isPresented: $showingAddReceipt) {
            AddReceiptView()
        }
        .onAppear {
            withAnimation(AppTheme.springAnimation.delay(0.3)) {
                animateFilters = true
            }
        }
    }
    
    // MARK: - Filter Picker
    private var filterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.spacing) {
                ForEach(Array(ReceiptFilter.allCases.enumerated()), id: \.element) { index, filter in
                    FilterChip(
                        title: filter.rawValue,
                        icon: filter.icon,
                        color: filter.color,
                        isSelected: selectedFilter == filter,
                        count: countForFilter(filter)
                    ) {
                        withAnimation(AppTheme.springAnimation) {
                            selectedFilter = filter
                        }
                        
                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }
                    .offset(x: animateFilters ? 0 : 50)
                    .opacity(animateFilters ? 1 : 0)
                    .animation(
                        AppTheme.springAnimation.delay(Double(index) * 0.1),
                        value: animateFilters
                    )
                }
            }
            .padding(.horizontal, AppTheme.spacing)
        }
        .padding(.vertical, AppTheme.smallSpacing)
    }
    
    // MARK: - Receipt List
    private var receiptList: some View {
        List {
            ForEach(Array(filteredReceipts.enumerated()), id: \.element.id) { index, receipt in
                NavigationLink(destination: ReceiptDetailView(receipt: receipt)) {
                    ReceiptRowView(receipt: receipt)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                .buttonStyle(PlainButtonStyle())
                .offset(x: animateFilters ? 0 : 100)
                .opacity(animateFilters ? 1 : 0)
                .animation(
                    AppTheme.springAnimation.delay(Double(index) * 0.05),
                    value: animateFilters
                )
            }
            .onDelete(perform: deleteReceipts)
        }
        .listStyle(PlainListStyle())
        .background(AppTheme.background)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.largeSpacing) {
            Spacer()
            
            EmptyStateView(
                title: emptyStateTitle,
                message: emptyStateMessage,
                systemImage: emptyStateIcon,
                actionTitle: searchText.isEmpty ? "Add Receipt" : nil,
                action: searchText.isEmpty ? { showingAddReceipt = true } : nil
            )
            .scaleTransition()
            
            Spacer()
        }
        .padding(AppTheme.largeSpacing)
    }
    
    // MARK: - Computed Properties
    
    private var filteredReceipts: [Receipt] {
        let filtered = receipts.filter { receipt in
            let matchesSearch = searchText.isEmpty || 
                (receipt.title?.localizedCaseInsensitiveContains(searchText) == true) ||
                (receipt.store?.localizedCaseInsensitiveContains(searchText) == true)
            
            let matchesFilter = matchesFilterCriteria(receipt)
            
            return matchesSearch && matchesFilter
        }
        
        return Array(filtered)
    }
    
    private func matchesFilterCriteria(_ receipt: Receipt) -> Bool {
        guard let expiryDate = receipt.expiryDate else { return selectedFilter == .all }
        
        let now = Date()
        let daysUntilExpiry = Calendar.current.dateComponents([.day], from: now, to: expiryDate).day ?? 0
        
        switch selectedFilter {
        case .all:
            return true
        case .active:
            return expiryDate > now
        case .expired:
            return expiryDate < now
        case .expiringSoon:
            return expiryDate > now && daysUntilExpiry <= 30
        }
    }
    
    private func countForFilter(_ filter: ReceiptFilter) -> Int {
        receipts.filter { receipt in
            guard let expiryDate = receipt.expiryDate else { return filter == .all }
            
            let now = Date()
            let daysUntilExpiry = Calendar.current.dateComponents([.day], from: now, to: expiryDate).day ?? 0
            
            switch filter {
            case .all:
                return true
            case .active:
                return expiryDate > now
            case .expired:
                return expiryDate < now
            case .expiringSoon:
                return expiryDate > now && daysUntilExpiry <= 30
            }
        }.count
    }
    
    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return "No Results Found"
        }
        
        switch selectedFilter {
        case .all:
            return "No Receipts Yet"
        case .active:
            return "No Active Warranties"
        case .expired:
            return "No Expired Warranties"
        case .expiringSoon:
            return "No Expiring Warranties"
        }
    }
    
    private var emptyStateMessage: String {
        if !searchText.isEmpty {
            return "Try adjusting your search terms or filters."
        }
        
        switch selectedFilter {
        case .all:
            return "Start by adding your first receipt to track warranties."
        case .active:
            return "All your warranties have expired. Add new receipts to track active warranties."
        case .expired:
            return "Great! All your warranties are still valid."
        case .expiringSoon:
            return "No warranties are expiring soon. You're all set!"
        }
    }
    
    private var emptyStateIcon: String {
        if !searchText.isEmpty {
            return "magnifyingglass"
        }
        
        switch selectedFilter {
        case .all:
            return "plus.circle"
        case .active:
            return "checkmark.shield.fill"
        case .expired:
            return "exclamationmark.triangle.fill"
        case .expiringSoon:
            return "clock.fill"
        }
    }
    
    // MARK: - Helper Methods
    
    private func deleteReceipts(offsets: IndexSet) {
        withAnimation(AppTheme.springAnimation) {
            offsets.map { filteredReceipts[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                print("Error deleting receipt: \(error)")
            }
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                
                Text(title)
                    .font(.caption.weight(.medium))
                
                Text("\(count)")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(isSelected ? .white : color.opacity(0.2))
                    )
            }
            .foregroundColor(isSelected ? color : AppTheme.secondaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? color.opacity(0.1) : AppTheme.cardBackground)
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? color.opacity(0.3) : Color.clear, lineWidth: 1.5)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(AppTheme.springAnimation, value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onTapGesture {
            withAnimation(AppTheme.springAnimation) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(AppTheme.springAnimation) {
                    isPressed = false
                }
            }
        }
    }
} 