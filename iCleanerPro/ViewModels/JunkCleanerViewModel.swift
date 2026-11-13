import Foundation

@MainActor
final class JunkCleanerViewModel: ObservableObject {
    enum GroupingMode: String, CaseIterable, Identifiable {
        case byCategory = "Theo loại"
        case bySizeTier = "Theo dung lượng"
        var id: String { rawValue }
    }

    @Published var items: [JunkItem] = []
    @Published var phase: ScanPhase = .idle
    @Published var groupingMode: GroupingMode = .byCategory
    @Published var selectedCategoryFilter: JunkCategory?
    @Published var lastSummary: JunkCleanupSummary?
    @Published var showDeleteConfirmation = false

    private let junkService = JunkCleanerService()

    var filteredItems: [JunkItem] {
        if let filter = selectedCategoryFilter {
            return items.filter { $0.category == filter }
        }
        return items
    }

    var totalFoundBytes: Int64 {
        items.reduce(0) { $0 + $1.sizeBytes }
    }

    var selectedBytes: Int64 {
        items.filter(\.isSelected).reduce(0) { $0 + $1.sizeBytes }
    }

    var selectedCount: Int {
        items.filter(\.isSelected).count
    }

    var allSelected: Bool {
        !items.isEmpty && items.allSatisfy(\.isSelected)
    }

    func scan() async {
        phase = .scanningJunk
        let scanned = await junkService.scanSandboxJunk()
        items = scanned
        phase = .completed
    }

    func toggleSelection(for id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].isSelected.toggle()
    }

    func toggleSelectAll() {
        let target = !allSelected
        for idx in items.indices {
            items[idx].isSelected = target
        }
    }

    func cleanSelected() async {
        guard selectedCount > 0 else { return }
        phase = .cleaning
        let summary = await junkService.cleanSelectedItems(items)
        lastSummary = summary
        items = await junkService.scanSandboxJunk()
        phase = .cleaned
    }

    /// Creates a real temporary diagnostic bundle in `tmp/` only when the user explicitly tests sandbox cleanup.
    func createSampleTempDiagnosticFile() {
        let tmpFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("diagnostic_snapshot_\(Int(Date().timeIntervalSince1970)).tmp")
        let payload = Data(repeating: 0x41, count: 512 * 1024) // Real 512 KB temp file on disk
        try? payload.write(to: tmpFile, options: .atomic)
    }
}
