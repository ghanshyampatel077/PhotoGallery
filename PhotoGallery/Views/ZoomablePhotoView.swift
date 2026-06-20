import Kingfisher
import SwiftUI

struct ZoomablePhotoView: View {
    
    // MARK: Input
    let imageURL: URL?
    let placeholderImageURL: URL?
    let onClose: () -> Void

    // MARK: Initialization
    init(imageURL: URL?, placeholderImageURL: URL? = nil, onClose: @escaping () -> Void) {
        self.imageURL = imageURL
        self.placeholderImageURL = placeholderImageURL
        self.onClose = onClose
    }

    // MARK: State
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    // MARK: Body
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black
                .ignoresSafeArea()

            GeometryReader { proxy in
                zoomableImage(in: proxy.size)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            closeButton
                .padding(.top, 16)
                .padding(.trailing, 16)
        }
        .statusBarHidden()
    }

    // MARK: Subviews
    private func zoomableImage(in containerSize: CGSize) -> some View {
        KFImage(imageURL)
            .placeholder {
                cachedPlaceholder
            }
            .onFailureImage(PhotoPlaceholder.image)
            .resizable()
            .scaledToFit()
            .scaleEffect(scale)
            .offset(offset)
            .gesture(pinchGesture(in: containerSize))
            .simultaneousGesture(panGesture(in: containerSize))
            .onTapGesture(count: 2, perform: toggleZoom)
            .accessibilityLabel(AppConstants.Accessibility.fullScreenPhoto)
    }

    private var cachedPlaceholder: some View {
        KFImage(placeholderImageURL)
            .placeholder {
                ProgressView()
                    .tint(.white)
            }
            .onFailureImage(PhotoPlaceholder.image)
            .resizable()
            .scaledToFit()
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: AppConstants.SystemImage.close)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(.black.opacity(0.55), in: Circle())
        }
        .accessibilityLabel(AppConstants.Accessibility.closePhoto)
    }

    // MARK: Gestures
    private func pinchGesture(in containerSize: CGSize) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = min(max(lastScale * value, 1), 5)
            }
            .onEnded { _ in
                lastScale = scale
                if scale == 1 {
                    resetPan()
                } else {
                    clampPan(in: containerSize)
                }
            }
    }

    private func panGesture(in containerSize: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > 1 else { return }
                let proposedOffset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
                offset = clampedOffset(proposedOffset, in: containerSize)
            }
            .onEnded { _ in
                guard scale > 1 else {
                    resetPan()
                    return
                }
                lastOffset = offset
            }
    }

    // MARK: Actions
    private func toggleZoom() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            if scale > 1 {
                scale = 1
                lastScale = 1
                resetPan()
            } else {
                scale = 2.5
                lastScale = 2.5
            }
        }
    }

    private func resetPan() {
        offset = .zero
        lastOffset = .zero
    }

    private func clampPan(in containerSize: CGSize) {
        offset = clampedOffset(offset, in: containerSize)
        lastOffset = offset
    }

    private func clampedOffset(_ proposedOffset: CGSize, in containerSize: CGSize) -> CGSize {
        let maxHorizontalOffset = max((containerSize.width * (scale - 1)) / 2, 0)
        let maxVerticalOffset = max((containerSize.height * (scale - 1)) / 2, 0)

        return CGSize(
            width: min(max(proposedOffset.width, -maxHorizontalOffset), maxHorizontalOffset),
            height: min(max(proposedOffset.height, -maxVerticalOffset), maxVerticalOffset)
        )
    }
}

// MARK: - Preview
#Preview {
    ZoomablePhotoView(
        imageURL: URL(string: AppConstants.PreviewData.zoomImageURL),
        onClose: {}
    )
}
