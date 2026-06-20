import Kingfisher
import SwiftUI

struct PhotoDetailView: View {
    
    // MARK: Environment
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PhotoDetailViewModel
    @State private var showErrorAlert = false
    @State private var showFullScreenImage = false
    @FocusState private var isTitleFocused: Bool
    private let onPhotoUpdated: (Int64, String) -> Void
    private let onPhotoDeleted: (Int64) -> Void

    // MARK: Initialization
    init(
        photo: Photo,
        repository: PhotoRepositoryProtocol,
        initialTitle: String? = nil,
        initialThumbnailURLString: String? = nil,
        onPhotoUpdated: @escaping (Int64, String) -> Void = { _, _ in },
        onPhotoDeleted: @escaping (Int64) -> Void = { _ in }
    ) {
        self.onPhotoUpdated = onPhotoUpdated
        self.onPhotoDeleted = onPhotoDeleted
        _viewModel = State(
            initialValue: PhotoDetailViewModel(
                photo: photo,
                repository: repository,
                initialTitle: initialTitle,
                initialThumbnailURLString: initialThumbnailURLString
            )
        )
    }

    // MARK: Body
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                fullImage
                titleField
                deleteButton
            }
            .padding(16)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(AppConstants.UI.photoDetailsTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(AppConstants.UI.save) {
                    if viewModel.save() {
                        onPhotoUpdated(viewModel.photoID, viewModel.title)
                        dismiss()
                    } else {
                        showErrorAlert = true
                    }
                }
                .disabled(!viewModel.canSave)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(AppConstants.UI.done) {
                    isTitleFocused = false
                }
            }
        }
        .alert(AppConstants.UI.deletePhotoQuestion, isPresented: $viewModel.showDeleteConfirmation) {
            Button(AppConstants.UI.delete, role: .destructive) {
                if viewModel.delete() {
                    onPhotoDeleted(viewModel.photoID)
                    dismiss()
                } else {
                    showErrorAlert = true
                }
            }
            Button(AppConstants.UI.cancel, role: .cancel) {}
        } message: {
            Text(AppConstants.UI.deletePhotoMessage)
        }
        .alert(AppConstants.UI.error, isPresented: $showErrorAlert) {
            Button(AppConstants.UI.ok, role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? AppConstants.Errors.genericFailure)
        }
        .fullScreenCover(isPresented: $showFullScreenImage) {
            ZoomablePhotoView(
                imageURL: URL(string: viewModel.imageURLString),
                placeholderImageURL: URL(string: viewModel.thumbnailURLString),
                onClose: {
                    showFullScreenImage = false
                }
            )
        }
    }

    // MARK: Subviews
    private var fullImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.cardBackground)

            KFImage(URL(string: viewModel.imageURLString))
                .placeholder {
                    cachedThumbnail
                }
                .onFailureImage(PhotoPlaceholder.image)
                .resizable()
                .scaledToFit()
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.60), lineWidth: 1)
        }
        .shadow(color: AppTheme.softShadow, radius: 16, x: 0, y: 10)
        .contentShape(Rectangle())
        .onTapGesture {
            showFullScreenImage = true
        }
    }

    private var cachedThumbnail: some View {
        KFImage(URL(string: viewModel.thumbnailURLString))
            .placeholder {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 260)
            }
            .onFailureImage(PhotoPlaceholder.image)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, minHeight: 260)
    }

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppConstants.UI.titleLabel)
                .font(.headline)
            TextField(AppConstants.UI.titlePlaceholder, text: $viewModel.title, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
                .focused($isTitleFocused)
                .submitLabel(.done)
                .onSubmit {
                    isTitleFocused = false
                }
        }
        .padding(14)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: AppTheme.softShadow.opacity(0.7), radius: 10, x: 0, y: 5)
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            viewModel.showDeleteConfirmation = true
        } label: {
            Label(AppConstants.UI.deletePhoto, systemImage: AppConstants.SystemImage.trash)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.red)
    }
}
