import QuotioApplication
import QuotioDomain
import XCTest

@testable import QuotioPresentation

@MainActor
final class MenuBarSettingsManagerTests: XCTestCase {
    func testSelectionCapacityIsIndependentForEachHost() {
        let manager = MenuBarSettingsManager(repository: MenuBarPreferencesRepositoryFake())
        manager.menuBarMaxItems = 1
        for host in ["host-a", "host-b"] {
            manager.currentHostID = host
            XCTAssertFalse(manager.isAtMaxItems)
            manager.addItem(.init(provider: "codex", accountKey: "same-account", hostID: host))
            XCTAssertTrue(manager.isAtMaxItems)
        }
        XCTAssertEqual(manager.selectedItems.count, 2)
        XCTAssertEqual(manager.currentItems.count, 1)
    }

    func testProviderSelectionPersistsWithoutRequestingFullMenuRebuild() {
        let repository = MenuBarPreferencesRepositoryFake()
        let manager = MenuBarSettingsManager(repository: repository)
        var changeCount = 0
        manager.setDidChangeHandler { _ in changeCount += 1 }

        manager.selectProvider(.claude)

        XCTAssertEqual(repository.savedPreferences.last?.selectedProvider, .claude)
        XCTAssertEqual(changeCount, 0)
    }
}

private final class MenuBarPreferencesRepositoryFake: MenuBarPreferencesRepository, @unchecked Sendable {
    private(set) var savedPreferences: [MenuBarPreferences] = []

    func load() -> MenuBarPreferences { MenuBarPreferences() }

    func save(_ preferences: MenuBarPreferences) {
        savedPreferences.append(preferences)
    }
}
