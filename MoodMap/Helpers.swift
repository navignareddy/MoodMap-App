import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a,r,g,b) = (255,(int>>8)*17,(int>>4&0xF)*17,(int&0xF)*17)
        case 6:  (a,r,g,b) = (255,int>>16,int>>8&0xFF,int&0xFF)
        case 8:  (a,r,g,b) = (int>>24,int>>16&0xFF,int>>8&0xFF,int&0xFF)
        default: (a,r,g,b) = (255,0,0,0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

struct DS {
    static let bg       = Color(hex: "111827")
    static let surface  = Color(hex: "1F2937")
    static let surface2 = Color(hex: "273548")
    static let border   = Color.white.opacity(0.09)
    static let textPrimary   = Color(hex: "F1F5F9")
    static let textSecondary = Color(hex: "94A3B8")
    static let textMuted     = Color(hex: "475569")
    static let accent   = Color(hex: "818CF8")
    static let accentAlt = Color(hex: "6EE7B7")
    static let danger   = Color(hex: "F87171")
    static let gold     = Color(hex: "FCD34D")
}

extension Date {
    var relativeString: String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: self, relativeTo: .now)
    }
    var timeString: String {
        let f = DateFormatter(); f.dateStyle = .none; f.timeStyle = .short
        return f.string(from: self)
    }
    var shortDateString: String {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .short
        return f.string(from: self)
    }
    var dayMonthString: String {
        let f = DateFormatter(); f.dateFormat = "d MMM"
        return f.string(from: self)
    }
}
