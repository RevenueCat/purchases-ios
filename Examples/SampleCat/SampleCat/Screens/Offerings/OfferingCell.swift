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

            if offering.products.isEmpty {
                Text("No packages")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text("\(offering.products.count) package\(offering.products.count > 1 ? "s" : "")")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(scheme == .dark ? Color.black : Color.white)
        .clipShape(.rect(cornerRadius: 12))
    }
}
