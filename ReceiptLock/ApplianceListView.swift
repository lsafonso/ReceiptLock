//
//  ApplianceListView.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//
//  ApplianceListView is a comprehensive SwiftUI view that displays and manages
//  a list of household appliances with warranty tracking capabilities.
//
//  Features:
//  - Display appliances in an expandable card format
//  - Search functionality across appliance names, brands, and models
//  - Filter appliances by warranty status (All, Valid, Expired, Expiring Soon)
//  - Add new appliances via floating action button
//  - Smooth animations and haptic feedback
//  - Empty state handling for different scenarios
//  - Core Data integration for persistence
//
//  Usage:
//  ```
//  ApplianceListView()
//      .environment(\.managedObjectContext, viewContext)
//  ```
//
//  Dependencies:
//  - CoreData framework
//  - SwiftUI framework
//  - AppTheme for consistent styling
//  - ExpandableApplianceCard component
//  - EmptyStateView component
//  - AddApplianceView for adding new appliances
//

import SwiftUI
import CoreData

/// A comprehensive view for displaying and managing household appliances with warranty tracking.
///
/// This view provides a complete interface for users to view, search, and filter their appliances.
/// It integrates with Core Data for persistence and includes smooth animations and haptic feedback
/// for an enhanced user experience.
///
/// The view automatically handles:
/// - Filtering appliances by warranty status
/// - Searching across appliance properties
/// - Displaying appropriate empty states
/// - Managing the add appliance workflow
struct ApplianceListView: View {
    // MARK: - Environment & Core Data
    
    /// The managed object context for Core Data operations
    @Environment(\.managedObjectContext) private var viewContext
    
    /// Fetched results for appliances, sorted by creation date (newest first)
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Appliance.createdAt, ascending: false)],
        animation: .default)
    private var appliances: FetchedResults<Appliance>
    
    // MARK: - State Properties
    
    /// Current search text entered by the user
    @State private var searchText = ""
    
    /// Currently selected filter for warranty status
    @State private var selectedFilter: ApplianceFilter = .all
    
    /// Controls the animation state of filter chips and appliance rows
    @State private var animateFilters = false
    
    // MARK: - Filter Enumeration
    
    /// Defines the available filter options for warranty status
    enum ApplianceFilter: String, CaseIterable {
        case all = "All"
        case valid = "Valid Warranty"
        case expired = "Expired Warranty"
        case expiringSoon = "Expiring Soon"
        
        /// SF Symbol icon name for the filter
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .valid: return "checkmark.circle.fill"
            case .expired: return "exclamationmark.triangle.fill"
            case .expiringSoon: return "clock.fill"
            }
        }
        
        /// Theme color for the filter
        var color: Color {
            switch self {
            case .all: return AppTheme.secondary
            case .valid: return AppTheme.success
            case .expired: return AppTheme.error
            case .expiringSoon: return AppTheme.warning
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppTheme.background
                    .ignoresSafeArea()
                
                VStack(spacing: AppTheme.spacing) {
                    // Filter Picker
                    filterPicker
                    
                    // Appliance List
                    if filteredAppliances.isEmpty {
                        emptyStateView
                    } else {
                        applianceList
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search appliances...")
            .onChange(of: searchText) { oldValue, newValue in
                // Search functionality - no need to collapse anything
            }
        }
        .onAppear {
            withAnimation(AppTheme.springAnimation.delay(0.3)) {
                animateFilters = true
            }
        }
        .onDisappear {
            // View disappeared - no cleanup needed
        }
    }
    
    // MARK: - Filter Picker
    
    /// Horizontal scrollable filter picker with animated chips
    private var filterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.spacing) {
                ForEach(Array(ApplianceFilter.allCases.enumerated()), id: \.element) { index, filter in
                    ApplianceFilterChip(
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
                        
                        // Filter changed - no need to collapse anything
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
        .padding(.vertical, AppTheme.spacing)
    }
    
    // MARK: - Appliance List
    
    /// Lazy vertical stack containing all filtered appliances
    private var applianceList: some View {
        List {
            ForEach(Array(filteredAppliances.enumerated()), id: \.element.id) { index, appliance in
                applianceRow(for: appliance, at: index)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }
        }
        .listStyle(PlainListStyle())
        .background(Color.clear)
        .padding(.horizontal, AppTheme.spacing)
        .padding(.top, AppTheme.smallSpacing)
    }
    
    /// Creates an individual appliance row with animations and transitions
    /// - Parameters:
    ///   - appliance: The appliance to display
    ///   - index: The position index for staggered animations
    /// - Returns: A configured ExpandableApplianceCard view
    private func applianceRow(for appliance: Appliance, at index: Int) -> some View {
        ExpandableApplianceCard(appliance: appliance)
            .offset(x: animateFilters ? 0 : 100)
            .opacity(animateFilters ? 1 : 0)
            .animation(
                AppTheme.springAnimation.delay(Double(index) * 0.05),
                value: animateFilters
            )
            .transition(.asymmetric(
                insertion: .scale(scale: 0.95).combined(with: .opacity),
                removal: .scale(scale: 0.95).combined(with: .opacity)
            ))
            .padding(.bottom, AppTheme.spacing) // Add spacing between rows
    }
    
    // MARK: - Empty State
    
    /// Displays appropriate empty state based on current search and filter conditions
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.largeSpacing) {
            Spacer()
            
            EmptyStateView(
                title: emptyStateTitle,
                message: emptyStateMessage,
                systemImage: emptyStateIcon
            )
            .scaleTransition()
            
            Spacer()
        }
        .padding(AppTheme.largeSpacing)
    }
    
    // MARK: - Computed Properties
    
    /// Filters appliances based on search text and selected filter criteria
    private var filteredAppliances: [Appliance] {
        let filtered = appliances.filter { appliance in
            let matchesSearch = searchText.isEmpty || 
                (appliance.name?.localizedCaseInsensitiveContains(searchText) == true) ||
                (appliance.brand?.localizedCaseInsensitiveContains(searchText) == true) ||
                (appliance.model?.localizedCaseInsensitiveContains(searchText) == true)
            
            let matchesFilter = matchesFilterCriteria(appliance)
            
            return matchesSearch && matchesFilter
        }
        
        return Array(filtered)
    }
    
    /// Determines if an appliance matches the currently selected filter criteria
    /// - Parameter appliance: The appliance to check
    /// - Returns: True if the appliance matches the filter criteria
    private func matchesFilterCriteria(_ appliance: Appliance) -> Bool {
        guard let expiryDate = appliance.warrantyExpiryDate else { return selectedFilter == .all }
        
        let now = Date()
        let daysUntilExpiry = Calendar.current.dateComponents([.day], from: now, to: expiryDate).day ?? 0
        
        switch selectedFilter {
        case .all:
            return true
        case .valid:
            return expiryDate > now
        case .expired:
            return expiryDate < now
        case .expiringSoon:
            return expiryDate > now && daysUntilExpiry <= 30
        }
    }
    
    /// Counts the number of appliances that match a specific filter
    /// - Parameter filter: The filter to count appliances for
    /// - Returns: The count of matching appliances
    private func countForFilter(_ filter: ApplianceFilter) -> Int {
        appliances.filter { appliance in
            guard let expiryDate = appliance.warrantyExpiryDate else { return filter == .all }
            
            let now = Date()
            let daysUntilExpiry = Calendar.current.dateComponents([.day], from: now, to: expiryDate).day ?? 0
            
            switch filter {
            case .all:
                return true
            case .valid:
                return expiryDate > now
            case .expired:
                return expiryDate < now
            case .expiringSoon:
                return expiryDate > now && daysUntilExpiry <= 30
            }
        }.count
    }
    
    /// Dynamic title for empty state based on current context
    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return "No Results Found"
        }
        
        switch selectedFilter {
        case .all:
            return "No Appliances Yet"
        case .valid:
            return "No Valid Warranties"
        case .expired:
            return "No Expired Warranties"
        case .expiringSoon:
            return "No Expiring Warranties"
        }
    }
    
    /// Dynamic message for empty state based on current context
    private var emptyStateMessage: String {
        if !searchText.isEmpty {
            return "Try adjusting your search terms or filters."
        }
        
        switch selectedFilter {
        case .all:
            return "Start by adding your first appliance to track warranties."
        case .valid:
            return "All your warranties have expired. Add new appliances to track valid warranties."
        case .expired:
            return "Great! All your warranties are still valid."
        case .expiringSoon:
            return "No warranties are expiring soon. You're all set!"
        }
    }
    
    /// Dynamic icon for empty state based on current context
    private var emptyStateIcon: String {
        if !searchText.isEmpty {
            return "magnifyingglass"
        }
        
        switch selectedFilter {
        case .all:
            return "plus.circle"
        case .valid:
            return "checkmark.shield.fill"
        case .expired:
            return "exclamationmark.triangle.fill"
        case .expiringSoon:
            return "clock.fill"
        }
    }
    
    // MARK: - Helper Methods
    
    /// Deletes appliances from Core Data context
    /// - Parameter offsets: Index set of appliances to delete
    private func deleteAppliances(offsets: IndexSet) {
        withAnimation(AppTheme.springAnimation) {
            offsets.map { filteredAppliances[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                print("Error deleting appliance: \(error)")
            }
        }
    }
}

// MARK: - Appliance Filter Chip

/// A customizable filter chip component for the appliance list view
///
/// This component displays a filter option with an icon, title, and count.
/// It provides visual feedback for selection state and includes haptic feedback
/// when tapped.
///
/// Features:
/// - Dynamic color theming based on filter type
/// - Animated selection states
/// - Press animations for better user feedback
/// - Count badge showing number of matching appliances
struct ApplianceFilterChip: View {
    // MARK: - Properties
    
    /// The display title for the filter
    let title: String
    
    /// SF Symbol icon name for the filter
    let icon: String
    
    /// Theme color for the filter
    let color: Color
    
    /// Whether this filter is currently selected
    let isSelected: Bool
    
    /// Number of appliances matching this filter
    let count: Int
    
    /// Action to perform when the chip is tapped
    let action: () -> Void
    
    /// Internal state for press animation
    @State private var isPressed = false
    
    // MARK: - Body
    
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
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(AppTheme.springAnimation, value: isSelected)
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
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(AppTheme.springAnimation, value: isSelected)
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
