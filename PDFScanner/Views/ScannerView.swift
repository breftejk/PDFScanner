import SwiftUI
import VisionKit

struct ScannerView: UIViewControllerRepresentable {
    @Binding var scannedImages: [UIImage]
    @Environment(\.presentationMode) var presentationMode

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let documentViewController = VNDocumentCameraViewController()
        documentViewController.delegate = context.coordinator
        return documentViewController
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var parent: ScannerView

        init(_ parent: ScannerView) {
            self.parent = parent
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            parent.scannedImages = []
            for i in 0..<scan.pageCount {
                parent.scannedImages.append(scan.imageOfPage(at: i))
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Document camera view controller did fail with error: \(error)")
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style = .light

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

#Preview {
    ScannerView(scannedImages: .constant([]))
        .environment(\.colorScheme, .dark)
        .previewLayout(.sizeThatFits)
        .frame(width: 300, height: 500)
}