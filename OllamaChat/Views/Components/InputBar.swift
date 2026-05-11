import SwiftUI
import PhotosUI

struct InputBar: View {
    @Binding var text: String
    let isStreaming: Bool
    let onSend: () -> Void
    let onCancel: () -> Void
    let onAttachPhoto: () -> Void
    let onAttachFile: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Attachment preview row
            AttachmentPreviewRow()
            
            // Input field + buttons
            HStack(alignment: .bottom, spacing: 8) {
                // Attachment button
                Menu {
                    Button {
                        onAttachPhoto()
                    } label: {
                        Label("Photo", systemImage: "photo")
                    }
                    
                    Button {
                        onAttachFile()
                    } label: {
                        Label("File", systemImage: "doc")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .disabled(isStreaming)
                
                // Text input
                TextField("Message...", text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...6)
                    .focused($isFocused)
                    .onSubmit {
                        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            onSend()
                        }
                    }
                
                // Send / Cancel button
                if isStreaming {
                    Button(action: onCancel) {
                        Image(systemName: "stop.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.red)
                    }
                } else {
                    Button(action: onSend) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(canSend ? .blue : .gray)
                    }
                    .disabled(!canSend)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.bar)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.bottom, 4)
        }
    }
    
    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !AttachmentManager.shared.attachments.isEmpty
    }
}

// MARK: - Attachment Preview Row

struct AttachmentPreviewRow: View {
    @ObservedObject var manager = AttachmentManager.shared
    
    var body: some View {
        if !manager.attachments.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(manager.attachments) { attachment in
                        AttachmentThumbnail(attachment: attachment) {
                            manager.remove(attachment)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }
            .background(Color(.secondarySystemBackground))
        }
    }
}

// MARK: - Attachment Thumbnail

struct AttachmentThumbnail: View {
    let attachment: Attachment
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let image = attachment.thumbnail {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.tertiarySystemBackground))
                        .frame(width: 56, height: 56)
                        .overlay(
                            VStack(spacing: 2) {
                                Image(systemName: attachment.isPDF ? "doc.richtext" : "doc.fill")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                                Text(attachment.fileExtension.uppercased())
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.secondary)
                            }
                        )
                }
            }
            
            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .background(Circle().fill(Color.black.opacity(0.6)))
            }
            .offset(x: 6, y: -6)
        }
    }
}

// MARK: - Attachment Manager

@MainActor
@Observable
final class AttachmentManager: ObservableObject {
    static let shared = AttachmentManager()
    
    var attachments: [Attachment] = []
    
    private init() {}
    
    func addPhoto(_ result: PhotosPickerItem) {
        Task {
            guard let data = try? await result.loadTransferable(type: Data.self) else { return }
            let image = UIImage(data: data)
            let name = result.itemIdentifier ?? "photo"
            let attachment = Attachment(
                data: data,
                imageName: name,
                thumbnail: image,
                isImage: true,
                fileName: "photo.jpg",
                fileExtension: "jpg",
                textContent: nil
            )
            attachments.append(attachment)
        }
    }
    
    func addImage(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        let attachment = Attachment(
            data: data,
            imageName: UUID().uuidString,
            thumbnail: image,
            isImage: true,
            fileName: "photo.jpg",
            fileExtension: "jpg",
            textContent: nil
        )
        attachments.append(attachment)
    }
    
    func addFile(url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        
        guard let data = try? Data(contentsOf: url) else { return }
        let fileName = url.lastPathComponent
        let ext = url.pathExtension.lowercased()
        let isImage = ["jpg", "jpeg", "png", "gif", "webp", "heic", "heif"].contains(ext)
        
        var thumbnail: UIImage? = nil
        if isImage {
            thumbnail = UIImage(data: data)
        } else if ext == "pdf" {
            thumbnail = PDFRenderer.renderThumbnail(data: data)
        }
        
        // Extract text content from supported file types
        var textContent: String? = nil
        let textExtensions = ["txt", "md", "json", "xml", "csv", "log", "swift", "py", "js", "ts", "html", "css", "yaml", "yml", "toml", "sh", "rb", "go", "rs", "java", "c", "cpp", "h", "hpp"]
        if textExtensions.contains(ext) {
            textContent = String(data: data, encoding: .utf8)
        }
        // PDF: rendered as images for vision, no text extraction needed
        
        let attachment = Attachment(
            data: data,
            imageName: nil,
            thumbnail: thumbnail,
            isImage: isImage,
            fileName: fileName,
            fileExtension: ext,
            textContent: textContent
        )
        attachments.append(attachment)
    }
    
    func remove(_ attachment: Attachment) {
        attachments.removeAll { $0.id == attachment.id }
    }
    
    func clear() {
        attachments.removeAll()
    }
}

// MARK: - PDF Rendering Helper

enum PDFRenderer {
    /// Render first page of a PDF as a thumbnail image
    @MainActor
    static func renderThumbnail(data: Data) -> UIImage? {
        renderPage(data: data, pageIndex: 1)
    }
    
    /// Render specified pages of a PDF as JPEG images for vision analysis
    @MainActor
    static func renderPages(data: Data, maxPages: Int = 5) -> [Data] {
        guard let provider = CGDataProvider(data: data as CFData),
              let cgPDF = CGPDFDocument(provider) else { return [] }
        
        let pageCount = min(cgPDF.numberOfPages, maxPages)
        var results: [Data] = []
        
        for i in 1...pageCount {
            guard let page = cgPDF.page(at: i) else { continue }
            let pageRect = page.getBoxRect(.mediaBox)
            let scale: CGFloat = 2.0
            let size = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)
            
            let renderer = UIGraphicsImageRenderer(size: size)
            let image = renderer.image { ctx in
                UIColor.white.setFill()
                ctx.fill(CGRect(origin: .zero, size: size))
                ctx.cgContext.concatenate(CGAffineTransform(a: scale, b: 0, c: 0, d: scale, tx: 0, ty: 0))
                ctx.cgContext.drawPDFPage(page)
            }
            
            if let jpegData = image.jpegData(compressionQuality: 0.7) {
                results.append(jpegData)
            }
        }
        
        return results
    }
    
    /// Render a single page of a PDF as a UIImage
    @MainActor
    private static func renderPage(data: Data, pageIndex: Int) -> UIImage? {
        guard let provider = CGDataProvider(data: data as CFData),
              let cgPDF = CGPDFDocument(provider),
              let page = cgPDF.page(at: pageIndex) else { return nil }
        
        let pageRect = page.getBoxRect(.mediaBox)
        let scale: CGFloat = 2.0
        let size = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            ctx.cgContext.concatenate(CGAffineTransform(a: scale, b: 0, c: 0, d: scale, tx: 0, ty: 0))
            ctx.cgContext.drawPDFPage(page)
        }
    }
}

// MARK: - Attachment Model

struct Attachment: Identifiable {
    let id = UUID()
    let data: Data
    let imageName: String?
    let thumbnail: UIImage?
    let isImage: Bool
    let fileName: String
    let fileExtension: String
    let textContent: String?
}

extension Attachment {
    /// Base64-encoded string for API submission
    var base64String: String {
        data.base64EncodedString()
    }
    
    /// Whether this attachment can be sent as an image to the vision API
    var isVisionCompatible: Bool {
        isImage && ["jpg", "jpeg", "png", "gif", "webp"].contains(fileExtension)
    }
    
    /// Whether this is a PDF that should be rendered as images for vision
    var isPDF: Bool {
        fileExtension == "pdf"
    }
    
    /// For text files: formatted content to include in the message
    var formattedTextContent: String? {
        guard let text = textContent else { return nil }
        return "\n\n📄 **\(fileName)**:\n```\n\(text)\n```"
    }
}