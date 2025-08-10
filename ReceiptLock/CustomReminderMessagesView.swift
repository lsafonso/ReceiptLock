//
//  CustomReminderMessagesView.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI

struct CustomReminderMessagesView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("customReminderMessages") private var messagesData: Data = Data()
    @State private var messages: [CustomReminderMessage] = []
    @State private var showingAddMessage = false
    @State private var editingMessage: CustomReminderMessage?
    
    private let defaultMessages = [
        CustomReminderMessage(
            title: "Warranty Expiring Soon",
            message: "Your warranty for {appliance} expires in {days} days. Consider extending it!",
            isEnabled: true,
            type: .warranty
        ),
        CustomReminderMessage(
            title: "Service Due",
            message: "It's time to service your {appliance}. Regular maintenance extends its life.",
            isEnabled: true,
            type: .service
        ),
        CustomReminderMessage(
            title: "Receipt Backup",
            message: "Don't forget to backup your receipt for {appliance} to keep it safe.",
            isEnabled: true,
            type: .backup
        ),
        CustomReminderMessage(
            title: "Renewal Reminder",
            message: "Your {appliance} warranty is up for renewal. Check for better deals!",
            isEnabled: true,
            type: .renewal
        )
    ]
    
    var body: some View {
        NavigationStack {
            List {
                Section("Default Messages") {
                    ForEach(defaultMessages) { message in
                        MessageRow(message: message, isEditable: false)
                    }
                }
                
                Section("Custom Messages") {
                    ForEach(messages) { message in
                        MessageRow(message: message, isEditable: true) {
                            editingMessage = message
                        }
                    }
                    .onDelete(perform: deleteMessages)
                    .onMove(perform: moveMessages)
                    
                    Button("Add Custom Message") {
                        showingAddMessage = true
                    }
                    .foregroundColor(AppTheme.primary)
                }
                
                Section("Message Variables") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Available Variables:")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• {appliance} - Appliance name")
                            Text("• {days} - Days remaining")
                            Text("• {date} - Expiry date")
                            Text("• {brand} - Brand name")
                            Text("• {model} - Model number")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Custom Reminder Messages")
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
            loadMessages()
        }
        .sheet(isPresented: $showingAddMessage) {
            AddEditMessageView { message in
                addMessage(message)
            }
        }
        .sheet(item: $editingMessage) { message in
            AddEditMessageView(message: message) { updatedMessage in
                updateMessage(updatedMessage)
            }
        }
    }
    
    private func loadMessages() {
        if let decoded = try? JSONDecoder().decode([CustomReminderMessage].self, from: messagesData) {
            messages = decoded
        }
    }
    
    private func saveMessages() {
        if let encoded = try? JSONEncoder().encode(messages) {
            messagesData = encoded
        }
    }
    
    private func addMessage(_ message: CustomReminderMessage) {
        messages.append(message)
        saveMessages()
    }
    
    private func updateMessage(_ message: CustomReminderMessage) {
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index] = message
            saveMessages()
        }
    }
    
    private func deleteMessages(at offsets: IndexSet) {
        messages.remove(atOffsets: offsets)
        saveMessages()
    }
    
    private func moveMessages(from source: IndexSet, to destination: Int) {
        messages.move(fromOffsets: source, toOffset: destination)
        saveMessages()
    }
}

struct MessageRow: View {
    let message: CustomReminderMessage
    let isEditable: Bool
    let onEdit: (() -> Void)?
    
    init(message: CustomReminderMessage, isEditable: Bool, onEdit: (() -> Void)? = nil) {
        self.message = message
        self.isEditable = isEditable
        self.onEdit = onEdit
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.title)
                        .font(.headline)
                    
                    Text(message.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isEditable, let onEdit = onEdit {
                    Button("Edit") {
                        onEdit()
                    }
                    .foregroundColor(AppTheme.primary)
                    .font(.caption)
                }
            }
            
            HStack {
                Text(message.type.rawValue.capitalized)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(message.type.color.opacity(0.2))
                    .foregroundColor(message.type.color)
                    .cornerRadius(4)
                
                Spacer()
                
                Toggle("", isOn: .constant(message.isEnabled))
                    .labelsHidden()
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddEditMessageView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (CustomReminderMessage) -> Void
    
    @State private var title = ""
    @State private var message = ""
    @State private var selectedType: ReminderMessageType = .custom
    @State private var isEnabled = true
    
    private let messageToEdit: CustomReminderMessage?
    
    init(message: CustomReminderMessage? = nil, onSave: @escaping (CustomReminderMessage) -> Void) {
        self.messageToEdit = message
        self.onSave = onSave
        
        if let message = message {
            _title = State(initialValue: message.title)
            _message = State(initialValue: message.message)
            _selectedType = State(initialValue: message.type)
            _isEnabled = State(initialValue: message.isEnabled)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Message Details") {
                    TextField("Title", text: $title)
                    
                    TextField("Message", text: $message, axis: .vertical)
                        .lineLimit(3...6)
                    
                    HStack {
                        Text("Type")
                        Spacer()
                        Picker("Type", selection: $selectedType) {
                            ForEach(ReminderMessageType.allCases, id: \.self) { type in
                                Text(type.rawValue.capitalized).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    HStack {
                        Text("Enabled")
                        Spacer()
                        Toggle("", isOn: $isEnabled)
                    }
                }
                
                Section("Preview") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sample Message:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(previewMessage)
                            .font(.body)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
            }
            .navigationTitle(messageToEdit == nil ? "Add Message" : "Edit Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newMessage = CustomReminderMessage(
                            id: messageToEdit?.id ?? UUID(),
                            title: title,
                            message: message,
                            isEnabled: isEnabled,
                            type: selectedType
                        )
                        onSave(newMessage)
                        dismiss()
                    }
                    .disabled(title.isEmpty || message.isEmpty)
                }
            }
        }
    }
    
    private var previewMessage: String {
        message
            .replacingOccurrences(of: "{appliance}", with: "iPhone 15 Pro")
            .replacingOccurrences(of: "{days}", with: "30")
            .replacingOccurrences(of: "{date}", with: "December 15, 2025")
            .replacingOccurrences(of: "{brand}", with: "Apple")
            .replacingOccurrences(of: "{model}", with: "A2849")
    }
}

struct CustomReminderMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let message: String
    let isEnabled: Bool
    let type: ReminderMessageType
    
    init(id: UUID = UUID(), title: String, message: String, isEnabled: Bool, type: ReminderMessageType) {
        self.id = id
        self.title = title
        self.message = message
        self.isEnabled = isEnabled
        self.type = type
    }
}

enum ReminderMessageType: String, CaseIterable, Codable {
    case warranty = "warranty"
    case service = "service"
    case backup = "backup"
    case renewal = "renewal"
    case custom = "custom"
    
    var color: Color {
        switch self {
        case .warranty:
            return .blue
        case .service:
            return AppTheme.success
        case .backup:
            return Color(red: 230/255, green: 154/255, blue: 100/255)
        case .renewal:
            return .purple
        case .custom:
            return .gray
        }
    }
}

#Preview {
    CustomReminderMessagesView()
}
