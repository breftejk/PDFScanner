import Foundation
import PDFKit

class PDFManager {
    static func createPDF(from images: [UIImage]) -> Data? {
        let pdfDocument = PDFDocument()
        for (index, image) in images.enumerated() {
            if let pdfPage = PDFPage(image: image) {
                pdfDocument.insert(pdfPage, at: index)
            }
        }
        return pdfDocument.dataRepresentation()
    }
}
