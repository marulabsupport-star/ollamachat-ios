import SwiftUI

struct ModelSelectorButton: View {
    let selectedModel: DisplayModel?
    let allModels: [DisplayModel]
    let modelGroups: [(title: String, models: [DisplayModel])]
    let onSelect: (DisplayModel) -> Void
    @Binding var isPresented: Bool
    
    var body: some View {
        Button(action: { isPresented.toggle() }) {
            HStack(spacing: 4) {
                if let imgName = AvailableModels.modelImageName(selectedModel?.id ?? "") {
                    Image(imgName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                }
                Circle()
                    .fill((selectedModel?.isCloud ?? true) ? Color.blue : Color.green)
                    .frame(width: 8, height: 8)
                
                Text(selectedModel?.attributedDisplayName ?? "Select Model")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
        }
        .popover(isPresented: $isPresented) {
            ModelPickerView(
                modelGroups: modelGroups,
                selectedModel: selectedModel,
                onSelect: { model in
                    onSelect(model)
                    isPresented = false
                }
            )
        }
    }
}

struct ModelPickerView: View {
    let modelGroups: [(title: String, models: [DisplayModel])]
    let selectedModel: DisplayModel?
    let onSelect: (DisplayModel) -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(modelGroups, id: \.title) { group in
                    Section(group.title) {
                        ForEach(group.models) { model in
                            ModelRow(model: model, isSelected: model.id == selectedModel?.id)
                                .onTapGesture { onSelect(model) }
                        }
                    }
                }
            }
            .navigationTitle("Select Model")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        .frame(minWidth: 300, minHeight: 400)
    }
}

struct ModelRow: View {
    let model: DisplayModel
    let isSelected: Bool
    
    var body: some View {
        HStack {
            if let imgName = AvailableModels.modelImageName(model.id) {
                Image(imgName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(model.attributedDisplayName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .bold : .regular)
                
                Text(model.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 2)
    }
}