import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var storeManager: StoreManager
    @State private var currentPage = 0

    var body: some View {
        VStack {
            Spacer()

            // Onboarding Carousel
            TabView(selection: $currentPage) {
                OnboardingPageView(
                    imageName: "doc.text.magnifyingglass",
                    title: "Scan Anything",
                    description: "Quickly scan documents, receipts, and whiteboards with high-quality output."
                ).tag(0)

                OnboardingPageView(
                    imageName: "square.and.arrow.up.fill",
                    title: "Share & Export",
                    description: "Easily save your scans as PDF files and share them anywhere."
                ).tag(1)

                OnboardingPageView(
                    imageName: "lock.shield.fill",
                    title: "Privacy First",
                    description: "All your scans are processed and stored securely on your device."
                ).tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .frame(height: 350)

            Spacer()

            // Call to Action
            VStack(spacing: 20) {
                Button(action: {
                    storeManager.purchasePro()
                }) {
                    Text("Start 3-day Free Trial")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                if let product = storeManager.products.first {
                    Text("then \(product.displayPrice)/year")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, -8)
                }

                Button(action: {
                    storeManager.restorePurchases()
                }) {
                    Text("Restore Purchases")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            UIPageControl.appearance().currentPageIndicatorTintColor = .gray
            UIPageControl.appearance().pageIndicatorTintColor = UIColor.gray.withAlphaComponent(0.2)
        }
    }
}

struct OnboardingPageView: View {
    let imageName: String
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: imageName)
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            Text(title)
                .font(.largeTitle.bold())
            
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

struct PaywallView_Previews: PreviewProvider {
    static var previews: some View {
        PaywallView()
            .environmentObject(StoreManager())
    }
}
