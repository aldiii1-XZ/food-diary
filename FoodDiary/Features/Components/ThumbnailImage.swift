import SwiftUI
import UIKit

/// Thumbnail dari disk; kalau file foto hilang, tampilkan placeholder —
/// tidak boleh crash (T-10).
struct ThumbnailImage: View {
    let filename: String
    let size: CGFloat

    var body: some View {
        Group {
            if let image = UIImage(contentsOfFile: ImageStore.shared.photoURL(for: filename).path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.quaternary.opacity(0.4))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
