import SwiftUI
import UniformTypeIdentifiers

#if os(iOS)
import PhotosUI
#endif

struct AttachmentMenu: View {
    #if os(iOS)
    @State private var selectedPhoto: PhotosPickerItem?
    #endif
    
    @State private var showingFilePicker = false
    
    let onImageSelected: (Data) -> Void
    let onFileSelected: (URL) -> Void
    
    var body: some View {
        #if os(iOS)
        Menu {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label("Photo Library", systemImage: "photo.on.rectangle")
            }
            
            Button {
                showingFilePicker = true
            } label: {
                Label("Document", systemImage: "doc")
            }
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.title3)
        }
        .onChange(of: selectedPhoto) { _, newItem in
            guard let newItem = newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    onImageSelected(data)
                }
            }
        }
        .fileImporter(isPresented: $showingFilePicker, allowedContentTypes: [.pdf, .plainText, .json]) { result in
            switch result {
            case .success(let url):
                onFileSelected(url)
            case .failure:
                break
            }
        }
        #else
        Button {
            showingFilePicker = true
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.title3)
        }
        .fileImporter(isPresented: $showingFilePicker, allowedContentTypes: [.pdf, .plainText, .json]) { result in
            switch result {
            case .success(let url):
                onFileSelected(url)
            case .failure:
                break
            }
        }
        #endif
    }
}