import SwiftUI

struct OfferingCell: View {
    @Environment(\.colorScheme) private var scheme
    let offering: OfferingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(offering.identifier)
                Spacer()
                Image(systemName: offering.icon)
                    .foregroundStyle(offering.color)
            }
            .font(.headline)
            .symbolRenderingMode(.hierarchical)
        }
        .padding()
        .background(scheme == .dark ? Color.black : Color.white)
        .clipShape(.rect(cornerRadius: 12))
    }
}
