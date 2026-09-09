import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)

//                VStack(spacing: 6) {
////                    Text("Bye JetLag")
////                        .font(.largeTitle)
////                        .fontWeight(.bold)
////                        .foregroundStyle(.white)
//                    Text("Arrive energized. Every time.")
//                        .font(.subheadline)
//                        .foregroundStyle(.white.opacity(0.8))
//                }
            }
        }
    }
}

#Preview {
    SplashView()
}
