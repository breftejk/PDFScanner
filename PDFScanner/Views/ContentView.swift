//
//  ContentView.swift
//  PDFScanner
//
//  Created by Marcin Kondrat on 7/31/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Item.timestamp, order: .reverse) private var items: [Item]
    @EnvironmentObject var storeManager: StoreManager
    @State private var showScanner = false
    @State private var scannedImages: [UIImage] = []

    var body: some View {
        Group {
            if storeManager.isPro {
                proTabView
                    .onChange(of: scannedImages) {
                        if let pdfData = PDFManager.createPDF(from: scannedImages), !scannedImages.isEmpty {
                            let newItem = Item(timestamp: Date(), pdfData: pdfData)
                            modelContext.insert(newItem)
                            scannedImages = []
                        }
                    }
                    .sheet(isPresented: $showScanner) {
                        ScannerView(scannedImages: $scannedImages)
                    }
            } else {
                PaywallView()
            }
        }
        .onAppear {
            UIPageControl.appearance().currentPageIndicatorTintColor = UIColor.systemGray
            UIPageControl.appearance().pageIndicatorTintColor = UIColor.systemGray2
        }
    }

    private var proTabView: some View {
        TabView {
            NavigationSplitView {
                VStack {
                    if items.isEmpty {
                        emptyStateView
                    } else {
                        listView
                    }
                }
                .navigationTitle("My Scans")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showScanner = true }) {
                            Image(systemName: "doc.viewfinder")
                                .font(.title2)
                        }
                    }
                }
            } detail: {
                detailPlaceholder
            }
            .tabItem {
                Label("Scans", systemImage: "doc.text.fill")
            }
            
            SubscriptionView()
                .tabItem {
                    Label("Subscription", systemImage: "creditcard.fill")
                }
        }
    }

    private var listView: some View {
        List {
            ForEach(items) { item in
                NavigationLink(destination: PDFDetailView(item: item)) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .font(.title)
                            .foregroundColor(.accentColor)
                        VStack(alignment: .leading) {
                            Text("Scan \(item.timestamp, formatter: itemFormatter)")
                                .font(.headline)
                            Text("PDF Document")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .onDelete(perform: deleteItems)
        }
        .listStyle(.insetGrouped)
    }

    private var emptyStateView: some View {
        VStack {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No Scans Yet")
                .font(.title.bold())
                .padding(.top)
            Text("Tap the scan button to get started.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private var detailPlaceholder: some View {
        VStack {
            Image(systemName: "arrow.left")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("Select a Scan")
                .font(.largeTitle.bold())
                .padding(.top)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct PDFDetailView: View {
    let item: Item
    
    @State private var tempPDFURL: URL? = nil
    
    var body: some View {
        VStack {
            if let data = item.pdfData {
                PDFKitView(data: data)
            } else {
                Text("No PDF Data Available")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Scan \(item.timestamp, formatter: itemFormatter)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let url = tempPDFURL {
                    ShareLink(item: url, preview: SharePreview("Scanned Document.pdf", image: Image(systemName: "doc.text.fill"))) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .onAppear {
            if let data = item.pdfData {
                tempPDFURL = createOrUpdateTempPDFFile(with: data)
            }
        }
        .onDisappear {
            if let url = tempPDFURL {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
    
    private func createOrUpdateTempPDFFile(with data: Data) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("ScannedDocument.pdf")
        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to write temp PDF: \(error)")
        }
        return fileURL
    }
}
