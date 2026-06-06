import SwiftUI
import SwiftData

struct PlaceReviewsView: View {
    let place: Place
    let mood: Mood
    @Query private var allReviews: [PlaceReview]

    var reviews: [PlaceReview] {
        allReviews.filter { $0.placeID == place.id }.sorted { $0.date > $1.date }
    }
    var averageRating: Double {
        guard !reviews.isEmpty else { return 0 }
        return Double(reviews.map(\.rating).reduce(0, +)) / Double(reviews.count)
    }

    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()
            if reviews.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "star.bubble").font(.system(size: 52)).foregroundStyle(DS.accent.opacity(0.5))
                    Text("No reviews yet").font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(DS.textPrimary)
                    Text("Be the first to share your experience!")
                        .font(.system(size: 14, design: .rounded)).foregroundStyle(DS.textSecondary)
                }
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        RatingSummaryCard2(reviews: reviews, averageRating: averageRating, mood: mood).padding(.horizontal, 16).padding(.top, 14)
                        ForEach(reviews) { ReviewCard(review: $0).padding(.horizontal, 16) }
                        Spacer(minLength: 30)
                    }
                }
            }
        }
        .navigationTitle("Reviews").navigationBarTitleDisplayMode(.inline).toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct RatingSummaryCard2: View {
    let reviews: [PlaceReview]; let averageRating: Double; let mood: Mood
    var body: some View {
        HStack(spacing: 18) {
            VStack(spacing: 4) {
                Text(String(format: "%.1f", averageRating))
                    .font(.system(size: 42, weight: .bold, design: .rounded)).foregroundStyle(DS.textPrimary)
                StarRow(rating: Int(averageRating.rounded()), size: 14)
                Text("\(reviews.count) review\(reviews.count == 1 ? "" : "s")")
                    .font(.system(size: 11, design: .rounded)).foregroundStyle(DS.textMuted)
            }
            Divider().background(DS.border).frame(height: 65)
            VStack(spacing: 5) {
                ForEach((1...5).reversed(), id: \.self) { star in
                    let count = reviews.filter { $0.rating == star }.count
                    let ratio = reviews.isEmpty ? 0.0 : Double(count) / Double(reviews.count)
                    HStack(spacing: 7) {
                        Text("\(star)").font(.system(size: 10, weight: .medium, design: .rounded)).foregroundStyle(DS.textMuted).frame(width: 8)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3).fill(DS.surface2)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(LinearGradient(colors: mood.gradient, startPoint: .leading, endPoint: .trailing))
                                    .frame(width: geo.size.width * ratio)
                            }
                        }.frame(height: 6)
                    }
                }
            }
        }
        .padding(18).background(DS.surface).clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(DS.border, lineWidth: 1))
    }
}

struct ReviewCard: View {
    let review: PlaceReview
    @State private var expanded = false
    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(LinearGradient(colors: review.mood.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 36, height: 36)
                    Text(review.mood.emoji).font(.system(size: 16))
                }
                VStack(alignment: .leading, spacing: 2) {
                    StarRow(rating: review.rating, size: 13)
                    Text(review.date.relativeString).font(.system(size: 11, design: .rounded)).foregroundStyle(DS.textMuted)
                }
                Spacer()
                Text(review.mood.rawValue).font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(review.mood.accentColor)
                    .padding(.horizontal, 7).padding(.vertical, 3).background(review.mood.accentColor.opacity(0.12)).clipShape(Capsule())
            }
            if !review.reviewText.isEmpty {
                Text(review.reviewText).font(.system(size: 13, design: .rounded)).foregroundStyle(DS.textPrimary)
                    .lineLimit(expanded ? nil : 3).onTapGesture { withAnimation { expanded.toggle() } }
                if review.reviewText.count > 100 {
                    Button { withAnimation { expanded.toggle() } } label: {
                        Text(expanded ? "Show less" : "Read more").font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(DS.accent)
                    }
                }
            }
            if !review.photoDataList.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(review.photoDataList.enumerated()), id: \.offset) { _, data in
                            if let img = UIImage(data: data) {
                                Image(uiImage: img).resizable().scaledToFill()
                                    .frame(width: 90, height: 72).clipShape(RoundedRectangle(cornerRadius: 9))
                            }
                        }
                    }
                }
            }
        }
        .padding(14).background(DS.surface).clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(DS.border, lineWidth: 1))
    }
}

struct StarRow: View {
    let rating: Int; var size: CGFloat = 16
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star").font(.system(size: size))
                    .foregroundStyle(star <= rating ? DS.gold : DS.textMuted.opacity(0.5))
            }
        }
    }
}
