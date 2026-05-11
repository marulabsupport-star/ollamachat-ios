import SwiftUI

struct RecentsScreen: View {
    @Bindable var viewModel: SessionsViewModel
    let onSelectSession: (ChatSession) -> Void
    let onNewChat: () -> Void
    let onOpenDrawer: () -> Void
    
    @State private var showingDeleteAlert = false
    @State private var sessionToDelete: ChatSession?
    
    // MARK: - Computed
    
    private var pinnedSessions: [ChatSession] {
        viewModel.sessions.filter { $0.pinned && !isEmptyChat($0) }
    }
    
    private var unpinnedSessions: [ChatSession] {
        viewModel.sessions.filter { !$0.pinned && !isEmptyChat($0) }
    }
    
    private func isEmptyChat(_ session: ChatSession) -> Bool {
        // Hide sessions that have no real messages (only title "New Chat" with no user messages)
        session.title == "New Chat" && session.messageCount == 0
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if viewModel.sessions.isEmpty {
                emptyState
            } else {
                sessionList
            }
        }
        .navigationTitle("Recents")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onOpenDrawer) {
                    Image(systemName: "line.3.horizontal")
                        .font(.title3)
                }
            }
            ToolbarItem(placement: .automatic) {
                Button(action: onNewChat) {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .alert("Delete Conversation?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let session = sessionToDelete {
                    viewModel.deleteSession(session)
                }
                sessionToDelete = nil
            }
        } message: {
            if let session = sessionToDelete {
                Text("This will permanently delete \"\(session.title)\" and all its messages.")
            }
        }
        .onAppear {
            viewModel.loadSessions()
        }
    }
    
    // MARK: - Sub-Views
    
    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No recent chats")
                .font(.title3)
                .fontWeight(.medium)
            Text("Start a new conversation")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var sessionList: some View {
        List {
            if !pinnedSessions.isEmpty {
                Section("Pinned") {
                    ForEach(pinnedSessions) { session in
                        SessionCard(session: session)
                            .onTapGesture { onSelectSession(session) }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    sessionToDelete = session
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    viewModel.unpinSession(session)
                                } label: {
                                    Label("Unpin", systemImage: "pin.slash")
                                }
                                .tint(.orange)
                            }
                    }
                }
            }
            
            Section(pinnedSessions.isEmpty ? "Recent" : "All Others") {
                ForEach(unpinnedSessions) { session in
                    SessionCard(session: session)
                        .onTapGesture { onSelectSession(session) }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                sessionToDelete = session
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                viewModel.pinSession(session)
                            } label: {
                                Label("Pin", systemImage: "pin")
                            }
                            .tint(.yellow)
                        }
                }
            }
        }
    }
}

// MARK: - Session Card

struct SessionCard: View {
    let session: ChatSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if session.pinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                }
                Text(session.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Text(session.modelName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(session.connectionMode == "cloud" ? Color.blue.opacity(0.15) : Color.green.opacity(0.15))
                    )
            }
            
            if let preview = session.lastMessagePreview, !preview.isEmpty {
                Text(preview)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            HStack(spacing: 8) {
                Text(session.updatedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}