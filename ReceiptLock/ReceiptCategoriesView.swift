//
//  ReceiptCategoriesView.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI

struct ReceiptCategoriesView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("receiptCategories") private var categoriesData: Data = Data()
    @State private var categories: [ReceiptCategory] = []
    @State private var showingAddCategory = false
    @State private var newCategoryName = ""
    @State private var newCategoryColor = Color.blue
    
    private let defaultCategories = [
        ReceiptCategory(name: "Electronics", color: .blue, icon: "laptopcomputer"),
        ReceiptCategory(name: "Appliances", color: .green, icon: "microwave"),
        ReceiptCategory(name: "Furniture", color: .orange, icon: "bed.double"),
        ReceiptCategory(name: "Clothing", color: .purple, icon: "tshirt"),
        ReceiptCategory(name: "Tools", color: .red, icon: "wrench.and.screwdriver"),
        ReceiptCategory(name: "Kitchen", color: .pink, icon: "fork.knife"),
        ReceiptCategory(name: "Bathroom", color: .cyan, icon: "shower"),
        ReceiptCategory(name: "Outdoor", color: .mint, icon: "leaf"),
        ReceiptCategory(name: "Sports", color: .indigo, icon: "sportscourt"),
        ReceiptCategory(name: "Other", color: .gray, icon: "questionmark.circle")
    ]
    
    var body: some View {
        NavigationStack {
            List {
                Section("Default Categories") {
                    ForEach(defaultCategories) { category in
                        CategoryRow(category: category, isEditable: false)
                    }
                }
                
                Section("Custom Categories") {
                    ForEach(categories) { category in
                        CategoryRow(category: category, isEditable: true) {
                            deleteCategory(category)
                        }
                    }
                    .onMove(perform: moveCategories)
                    
                    Button("Add Custom Category") {
                        showingAddCategory = true
                    }
                    .foregroundColor(AppTheme.primary)
                }
            }
            .navigationTitle("Receipt Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
        .onAppear {
            loadCategories()
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategoryView { category in
                addCategory(category)
            }
        }
    }
    
    private func loadCategories() {
        if let decoded = try? JSONDecoder().decode([ReceiptCategory].self, from: categoriesData) {
            categories = decoded
        }
    }
    
    private func saveCategories() {
        if let encoded = try? JSONEncoder().encode(categories) {
            categoriesData = encoded
        }
    }
    
    private func addCategory(_ category: ReceiptCategory) {
        categories.append(category)
        saveCategories()
    }
    
    private func deleteCategory(_ category: ReceiptCategory) {
        categories.removeAll { $0.id == category.id }
        saveCategories()
    }
    
    private func moveCategories(from source: IndexSet, to destination: Int) {
        categories.move(fromOffsets: source, toOffset: destination)
        saveCategories()
    }
}

struct CategoryRow: View {
    let category: ReceiptCategory
    let isEditable: Bool
    let onDelete: (() -> Void)?
    
    init(category: ReceiptCategory, isEditable: Bool, onDelete: (() -> Void)? = nil) {
        self.category = category
        self.isEditable = isEditable
        self.onDelete = onDelete
    }
    
    var body: some View {
        HStack {
            Image(systemName: category.icon)
                .foregroundColor(category.color)
                .font(.title3)
                .frame(width: 24)
            
            Text(category.name)
                .font(.body)
            
            Spacer()
            
            if isEditable, let onDelete = onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct AddCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (ReceiptCategory) -> Void
    
    @State private var categoryName = ""
    @State private var selectedColor = Color.blue
    @State private var selectedIcon = "questionmark.circle"
    
    private let colorOptions: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal, .cyan, .blue, .indigo, .purple, .pink, .brown
    ]
    
    private let iconOptions = [
        "questionmark.circle", "star", "heart", "bolt", "flame", "leaf", "drop", "snowflake",
        "sun.max", "moon", "cloud", "umbrella", "gift", "crown", "diamond", "sparkles"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Category Details") {
                    TextField("Category Name", text: $categoryName)
                    
                    HStack {
                        Text("Color")
                        Spacer()
                        ForEach(colorOptions, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    
                    HStack {
                        Text("Icon")
                        Spacer()
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                            ForEach(iconOptions, id: \.self) { icon in
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundColor(selectedIcon == icon ? selectedColor : .secondary)
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedIcon == icon ? selectedColor.opacity(0.2) : Color.clear)
                                    )
                                    .onTapGesture {
                                        selectedIcon = icon
                                    }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let newCategory = ReceiptCategory(
                            name: categoryName,
                            color: selectedColor,
                            icon: selectedIcon
                        )
                        onAdd(newCategory)
                        dismiss()
                    }
                    .disabled(categoryName.isEmpty)
                }
            }
        }
    }
}

struct ReceiptCategory: Identifiable, Codable, Equatable {
    let id = UUID()
    let name: String
    let color: Color
    let icon: String
    
    enum CodingKeys: String, CodingKey {
        case name, color, icon
    }
    
    init(name: String, color: Color, icon: String) {
        self.name = name
        self.color = color
        self.icon = icon
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decode(String.self, forKey: .icon)
        
        let colorData = try container.decode(Data.self, forKey: .color)
        color = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData)?.swiftUIColor ?? .blue
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(icon, forKey: .icon)
        
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor(color), requiringSecureCoding: false) {
            try container.encode(colorData, forKey: .color)
        }
    }
}

extension Color {
    var uiColor: UIColor {
        UIColor(self)
    }
}

extension UIColor {
    var swiftUIColor: Color {
        Color(self)
    }
}

#Preview {
    ReceiptCategoriesView()
}
