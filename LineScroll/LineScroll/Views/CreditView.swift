import SwiftUI

struct CreditView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Source credit")
                        .font(.title2.weight(.semibold))

                    Text(
                        """
                        LineScroll is an independent reading app. It is not affiliated with, endorsed by, or an official product of Project Gutenberg Literary Archive Foundation.

                        Book texts and catalog metadata shown here come from Project Gutenberg and are provided for personal reading. Most Project Gutenberg works are public domain in the United States. If you are outside the U.S., you are responsible for checking copyright law in your country before downloading or reading.
                        """
                    )

                    Text("Trademark")
                        .font(.headline)
                    Text(
                        """
                        “Project Gutenberg” is a registered trademark. LineScroll credits Project Gutenberg as the source of public-domain texts and does not present itself as a Project Gutenberg trademarked product.
                        """
                    )

                    Text("Catalog & downloads")
                        .font(.headline)
                    Text(
                        """
                        This MVP uses Gutendex (gutendex.com), an unofficial JSON wrapper of the Project Gutenberg catalog, for browse/search. Downloads follow the plain-text URLs listed in that catalog and identify the app with a contactable User-Agent. For production-scale use, prefer hosting your own index from the official RDF/CSV dump and using approved mirrors.
                        """
                    )

                    Text("License notices")
                        .font(.headline)
                    Text(
                        """
                        When present, Project Gutenberg header and footer license text is stripped from the reading view for clarity. The terms still apply to the downloaded files retained on your device. Visit gutenberg.org for the full Project Gutenberg License.
                        """
                    )

                    Link("Project Gutenberg", destination: URL(string: "https://www.gutenberg.org")!)
                    Link("Gutendex", destination: URL(string: "https://gutendex.com")!)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Credit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
