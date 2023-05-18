import SwiftUI

struct Avatar: View {
    let size: Double

    var body: some View {
        ZStack {
            Color.pink

            LinearGradient(colors: [.pink, .blue], startPoint: .topLeading, endPoint: .init(x: 1.5, y: 2))

            LinearGradient(colors: [.white, .black], startPoint: .topLeading, endPoint: .init(x: 1.5, y: 1))
                .blendMode(.hardLight)
                .opacity(0.2)

            Image(systemName: "person.fill")
                .resizable()
                .foregroundColor(.black)
                .opacity(0.5)
                .padding(8 * size / 120)
                .offset(y: 8 * size / 120)
                .blendMode(.overlay)
        }
        .compositingGroup()
        .contrast(1.2)
        .clipShape(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .frame(width: size, height: size)
    }
}

struct Avatar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ForEach([Double(40), 80, 120], id: \.self) { size in
                Avatar(size: size)
            }
        }
        .padding(40)
        .background(Color.black)
        .cornerRadius(24)
    }
}
