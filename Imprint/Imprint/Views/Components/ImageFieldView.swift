import SwiftUI
import PhotosUI

/// A reusable component for selecting and displaying images in the record form.
///
/// Renders as a tappable area that opens the photo library via `PhotosPicker`.
/// When an image is selected, it shows a preview with a remove button.
struct ImageFieldView: View {

    /// The selected image data (JPEG). Nil when no image is chosen.
    @Binding var imageData: Data?

    var isDark: Bool = false

    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 12) {
            if let imageData, let uiImage = UIImage(data: imageData) {
                // Preview selected image
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        self.imageData = nil
                        self.selectedItem = nil
                    }
                } label: {
                    Text("Remove image")
                        .font(ImprintFonts.jetBrainsMedium(13))
                        .foregroundStyle(ImprintColors.required)
                }
                .buttonStyle(.plain)
            } else {
                // Photo picker trigger
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 24))
                            .foregroundStyle(ImprintColors.secondaryText(isDark))

                        Text("Add image")
                            .font(ImprintFonts.jetBrainsMedium(14))
                            .foregroundStyle(ImprintColors.secondaryText(isDark))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(ImprintColors.inputBg(isDark))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(ImprintColors.inputBorder(isDark), lineWidth: 2)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            imageData = data
                        }
                    }
                }
            }
        }
    }
}
