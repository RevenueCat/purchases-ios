import SwiftUI

struct ConceptIntroductionView: View {
    let imageName: String
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 32) {
            Image(imageName)
                .resizable()
                .frame(width: 280, height: 280)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                Text(description)
            }
            .padding(.horizontal, 24)
            .multilineTextAlignment(.center)
        }
        .padding(.vertical, 32)
    }
}

#Preview {
    ConceptIntroductionView(
        imageName: "visual-products",
        title: "Products",
        description: "Products are the individual in-app purchases and subscriptions that you have set up on the App Store."
    )
}
