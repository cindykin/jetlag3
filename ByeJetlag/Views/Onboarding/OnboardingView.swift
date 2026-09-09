import SwiftUI

struct OnboardingView: View {
    
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    var body: some View {
        
        ZStack(alignment: .topTrailing) {
            
            ScrollView {
                VStack(spacing: 40) {
                    
                    // HEADER
                    VStack(spacing: 16) {
                        Text("Say no more to jet lag\nand arrive energized?")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                        
                        Text("Simple as taking small actions at one time")
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 80)
                    
                    // BLOCKS
                    VStack(spacing: 24) {
                        
                        // LIGHT
                        VStack(spacing: 12) {
                            Text("When to see bright light or avoid light")
                                .foregroundStyle(.gray)
                            
                            DualBlock(
                                left: ActionBlock(
                                    title: "Seek Light",
                                    icon: "sun.max.fill",
                                    bgColor: .lightPrimary
                                ),
                                right: ActionBlock(
                                    title: "Avoid Light",
                                    icon: "sun.max",
                                    bgColor: .white,
                                    textColor: .lightPrimary,
                                    borderColor: .lightPrimary
                                )
                            )
                        }
                        
                        // SLEEP
                        VStack(spacing: 12) {
                            Text("When go to sleep or take a nap")
                                .foregroundStyle(.gray)
                            
                            DualBlock(
                                left: ActionBlock(
                                    title: "Go to Sleep",
                                    icon: "bed.double.fill",
                                    bgColor: .sleepPrimary
                                ),
                                right: ActionBlock(
                                    title: "Take a nap\n(if can)",
                                    icon: "bed.double",
                                    bgColor: .white,
                                    textColor: .sleepPrimary,
                                    borderColor: .sleepPrimary
                                )
                            )
                        }
                        
                        // CAFFEINE (FIXED LAYOUT)
                        VStack(spacing: 12) {
                            Text("Optional for optimize your schedule if you want")
                                .foregroundStyle(.gray)
                            
                            TripleBlock()
                            
                            Text("More option to melatonin, caffeine to boost energy level, sleep better, shift even faster")
                                .font(.footnote)
                                .foregroundStyle(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // IMAGE
                    Image("onboard1")
                        .resizable()
                        .scaledToFit()
                        .padding(.horizontal)
                    
                    Text("No need to remember die-hard schedule!\nWe will tell you exactly what to do and when to do it")
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Image("onboard2")
                        .resizable()
                        .scaledToFit()
                        .padding(.horizontal)
                    
                    Text("If confuse, you can always see more info by tapping on any block!")
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text("You don’t have to do everything perfectly, but the more you stick to our guide the less jet lag you will experience")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // FINAL BLOCK
                    DualBlock(
                        left: ActionBlock(
                            title: "Go to Sleep",
                            icon: "bed.double.fill",
                            bgColor: .sleepPrimary
                        ),
                        right: ActionBlock(
                            title: "Take a nap\n(if can)",
                            icon: "bed.double",
                            bgColor: .white,
                            textColor: .sleepPrimary,
                            borderColor: .sleepPrimary
                        )
                    )
                    .padding(.horizontal)
                    
                    DualBlock(
                        left: ActionBlock(
                            title: "Avoid Light",
                            icon: "sun.max",
                            bgColor: .white,
                            textColor: .lightPrimary,
                            borderColor: .lightPrimary
                        ),
                        right: ActionBlock(
                            title: "Seek Light",
                            icon: "sun.max.fill",
                            bgColor: .lightPrimary
                        )
                    )
                    .padding(.horizontal)
                    
                    // BUTTON
                    Button {
                        hasSeenOnboarding = true
                    } label: {
                        Text("Let's Go")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.lightPrimary)
                            .foregroundStyle(.white)
                            .cornerRadius(25)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                    
                    Text("GOOOD JOB! You have reach this section means you are ready for your trip planning!")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            // SKIP
            Button("Skip") {
                hasSeenOnboarding = true
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.9))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.lightPrimary, lineWidth: 1)
            )
            .cornerRadius(20)
            .padding(.top, 20)
            .padding(.trailing, 20)
        }
    }
}


// MARK: - COMPONENTS

struct ActionBlock: View {
    var title: String
    var icon: String
    var bgColor: Color
    var textColor: Color = .white
    var borderColor: Color? = nil
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 90)
        .padding()
        .background(bgColor)
        .foregroundStyle(textColor)
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .inset(by: 0.5) // 🔥 border inside
                .stroke(borderColor ?? .clear, lineWidth: 1)
        )
    }
}

struct DualBlock: View {
    var left: ActionBlock
    var right: ActionBlock
    
    var body: some View {
        HStack(spacing: 0) {
            left.frame(maxWidth: .infinity)
            right.frame(maxWidth: .infinity)
        }
    }
}

struct TripleBlock: View {
    var body: some View {
        
        let totalHeight: CGFloat = 180
        let halfHeight = totalHeight / 2
        
        HStack(spacing: 0) {
            
            VStack(spacing: 0) {
                ActionBlock(
                    title: "Caffeine",
                    icon: "cup.and.saucer.fill",
                    bgColor: .caffeinePrimary
                )
                .frame(height: halfHeight)
                
                ActionBlock(
                    title: "No Caffeine",
                    icon: "cup.and.saucer",
                    bgColor: .white,
                    textColor: .caffeinePrimary,
                    borderColor: .caffeinePrimary
                )
                .frame(height: halfHeight)
            }
            .frame(maxWidth: .infinity)
            
            ActionBlock(
                title: "Take melatonin\nGo to Sleep",
                icon: "pills.fill",
                bgColor: .sleepPrimary
            )
            .frame(maxWidth: .infinity)
            .frame(height: totalHeight)
        }
        .frame(height: totalHeight)
    }
}

// MARK: - COLORS

extension Color {
    static let lightPrimary = Color(hex: "#DE6400")
    static let sleepPrimary = Color(hex: "#163F85")
    static let caffeinePrimary = Color(hex: "#855216")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        self.init(
            .sRGB,
            red: Double((int >> 16) & 0xFF) / 255,
            green: Double((int >> 8) & 0xFF) / 255,
            blue: Double(int & 0xFF) / 255,
            opacity: 1
        )
    }
}
