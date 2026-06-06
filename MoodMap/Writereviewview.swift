
import SwiftUI
import SwiftData
import PhotosUI

struct WriteReviewView: View {
    let place: Place
    let mood: Mood

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @State private var rating      = 0
    @State private var reviewText  = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoImages: [UIImage] = []
    @State private var isSaving    = false
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0F0C29").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: mood.gradient,
                                                         startPoint: .topLeading,
                                                         endPoint: .bottomTrailing))
                                    .frame(width: 52, height: 52)
                                Text(mood.emoji).font(.system(size: 24))
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(place.name)
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                Text(place.category)
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundStyle(mood.accentColor)
                            }
                            Spacer()
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        VStack(alignment: .leading, spacing: 12) {
                            Label("Your Rating", systemImage: "star.fill")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))

                            HStack(spacing: 10) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .font(.system(size: 36))
                                        .foregroundStyle(star <= rating
                                            ? Color(hex: "FBBF24")
                                            : Color.white.opacity(0.2))
                                        .scaleEffect(star <= rating ? 1.1 : 1.0)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: rating)
                                        .onTapGesture { withAnimation { rating = star } }
                                }
                                Spacer()
                                if rating > 0 {
                                    Text(ratingLabel)
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundStyle(Color(hex: "FBBF24"))
                                        .transition(.opacity.combined(with: .scale))
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        VStack(alignment: .leading, spacing: 12) {
                            Label("Your Experience", systemImage: "text.bubble.fill")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))

                            ZStack(alignment: .topLeading) {
                                if reviewText.isEmpty {
                                    Text("What was it like? Share the vibe, highlights, tips for others…")
                                        .font(.system(size: 14, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.25))
                                        .padding(.top, 8)
                                        .padding(.leading, 4)
                                }
                                TextEditor(text: $reviewText)
                                    .font(.system(size: 15, design: .rounded))
                                    .foregroundStyle(.white)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 120)
                                    .tint(mood.accentColor)
                            }

                            HStack {
                                Spacer()
                                Text("\(reviewText.count)/500")
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .onChange(of: reviewText) { _, new in
                            if new.count > 500 { reviewText = String(new.prefix(500)) }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Label("Add Photos", systemImage: "photo.on.rectangle.angled")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))

                            if !photoImages.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(Array(photoImages.enumerated()), id: \.offset) { idx, img in
                                            ZStack(alignment: .topTrailing) {
                                                Image(uiImage: img)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 90, height: 90)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))

                                                Button {
                                                    photoImages.remove(at: idx)
                                                    if idx < selectedPhotos.count {
                                                        selectedPhotos.remove(at: idx)
                                                    }
                                                } label: {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.system(size: 20))
                                                        .foregroundStyle(.white)
                                                        .shadow(radius: 4)
                                                }
                                                .offset(x: 6, y: -6)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }

                            PhotosPicker(
                                selection: $selectedPhotos,
                                maxSelectionCount: 5,
                                matching: .images
                            ) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 18))
                                    Text(photoImages.isEmpty ? "Add up to 5 photos" : "Add more photos")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                }
                                .foregroundStyle(mood.accentColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(mood.accentColor.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(mood.accentColor.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .onChange(of: selectedPhotos) { _, newItems in
                                Task { await loadPhotos(from: newItems) }
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        Button { saveReview() } label: {
                            HStack(spacing: 10) {
                                if isSaving {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.85)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                        .font(.system(size: 16))
                                    Text("Post Review")
                                        .font(.system(size: 17, weight: .bold, design: .rounded))
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                rating > 0
                                    ? LinearGradient(colors: mood.gradient,
                                                     startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [.gray.opacity(0.4), .gray.opacity(0.3)],
                                                     startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: rating > 0 ? mood.accentColor.opacity(0.4) : .clear,
                                    radius: 12, y: 5)
                        }
                        .disabled(rating == 0 || isSaving)

                        Spacer(minLength: 30)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Write a Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .overlay {
                if showSuccess {
                    SuccessToastOverlay(message: "Review posted! 🎉")
                }
            }
        }
    }

    var ratingLabel: String {
        switch rating {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Great"
        case 5: return "Amazing!"
        default: return ""
        }
    }

    func loadPhotos(from items: [PhotosPickerItem]) async {
        var images: [UIImage] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let img  = UIImage(data: data) {
                images.append(img)
            }
        }
        await MainActor.run { photoImages = images }
    }

    func saveReview() {
        isSaving = true
        let photoData = photoImages.compactMap {
            $0.jpegData(compressionQuality: 0.7)
        }
        let review = PlaceReview(
            placeID:       place.id,
            placeName:     place.name,
            placeCategory: place.category,
            mood:          mood,
            rating:        rating,
            reviewText:    reviewText,
            photoDataList: photoData,
            latitude:      place.latitude,
            longitude:     place.longitude
        )
        modelContext.insert(review)
        try? modelContext.save()

        withAnimation {
            showSuccess = true
            isSaving    = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
    }
}

struct SuccessToastOverlay: View {
    let message: String
    var body: some View {
        VStack {
            Spacer()
            Text(message)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color(hex: "059669"))
                .clipShape(Capsule())
                .shadow(radius: 10)
                .padding(.bottom, 60)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
