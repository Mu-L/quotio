import QuotioHostClient
import Foundation
import QuotioApplication
import QuotioDomain
import XCTest
@testable import QuotioInfrastructure

final class QuotioCLIBackendTests: XCTestCase {
    func testResolvedMutationsPreserveAccountAndSourceScopesAndExplicitNameReset() async throws {
        let backend = QuotioCLIBackend(session: stubSession())
        await backend.connect(.init(baseURL: URL(string: "http://127.0.0.1:43210")!, token: "test"))
        for _ in 0..<4 { QuotioCLIURLProtocol.enqueue(#"{"id":"operation","status":"completed"}"#) }
        try await backend.renameResolvedAccount(id: "logical", userLabel: nil)
        let body = try XCTUnwrap(QuotioCLIURLProtocol.body(forPath: "/v2/accounts/logical"))
        let reset = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertTrue(reset["user_label"] is NSNull)
        XCTAssertEqual(reset.count, 1)
        try await backend.setResolvedEnabled(false, target: .account("logical"))
        try await backend.setResolvedEnabled(false, target: .source("source"))
        try await backend.removeResolved(.source("source"))
        let requests = QuotioCLIURLProtocol.requests()
        XCTAssertEqual(requests.map { $0.url?.path }, ["/v2/accounts/logical", "/v2/accounts/logical", "/v2/sources/source", "/v2/sources/source"])
        XCTAssertEqual(requests.map(\.httpMethod), ["PATCH", "PATCH", "PATCH", "DELETE"])
        XCTAssertTrue(requests.allSatisfy { $0.value(forHTTPHeaderField: "Idempotency-Key") != nil })
    }

    func testResolvedAccountReadUsesRustNamesGroupsAndActionsUnchanged() async throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("../../../../").standardizedFileURL
        let data = try Data(contentsOf: root.appendingPathComponent("apps/cli/tests/fixtures/contracts/accounts-v2.json"))
        QuotioCLIURLProtocol.enqueue(try XCTUnwrap(String(data: data, encoding: .utf8)))
        let backend = QuotioCLIBackend(session: stubSession())
        await backend.connect(.init(baseURL: URL(string: "http://127.0.0.1:43210")!, token: "test"))
        let result = try await backend.resolvedAccounts()
        XCTAssertEqual(result.accounts.count, 1)
        XCTAssertEqual(result.accounts[0].id, "source-a")
        XCTAssertEqual(result.accounts[0].displayName, "Work")
        XCTAssertEqual(result.accounts[0].sources.count, 2)
        XCTAssertEqual(result.accounts[0].actions.map(\.kind), ["rename", "set_enabled", "select", "remove"])
        XCTAssertEqual(result.accounts[0].state, "not_checked")
        XCTAssertEqual(QuotioCLIURLProtocol.requests().last?.url?.path, "/v2/accounts")
        var incompatible = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        incompatible["schema_version"] = 3
        QuotioCLIURLProtocol.enqueue(try XCTUnwrap(String(data: JSONSerialization.data(withJSONObject: incompatible), encoding: .utf8)))
        do {
            _ = try await backend.resolvedAccounts()
            XCTFail("Unsupported contract must not reach the frontend")
        } catch QuotioHostClientError.incompatible {}
    }

    func testSuccessfulAccountReadClearsPreviousStoragePermissionFailure() async throws {
        let backend = QuotioCLIBackend(session: stubSession())
        await backend.connect(.init(baseURL: URL(string: "http://127.0.0.1:43210")!, token: "test"))
        QuotioCLIURLProtocol.enqueue(#"{"error":"credential_storage_unavailable"}"#, status: 503)
        _ = await backend.accounts()
        let blocked = await backend.accountStorageRequiresAuthorization()
        XCTAssertTrue(blocked)
        QuotioCLIURLProtocol.enqueue(try hostFixture { $0["accounts"] = []; $0["usage"] = [] })
        _ = await backend.accounts()
        let recovered = await backend.accountStorageRequiresAuthorization()
        XCTAssertFalse(recovered)
    }

    func testGrantingQuotioStorageAutomaticallyRetriesNativeDiscovery() async throws {
        let providers = #"{"schema_version":1,"providers":[{"id":"codex","capabilities":{"source_references":[{"kind":"codex_native","platforms":["macos"],"origin":"borrowed_native"}]}}]}"#
        let discovery = #"{"schema_version":1,"status":"checked","candidates":[{"status":"available","source":{"kind":"codex_native","location":"default"}}]}"#
        QuotioCLIURLProtocol.enqueue(providers)
        QuotioCLIURLProtocol.enqueue(discovery)
        QuotioCLIURLProtocol.enqueue(#"{"error":"credential_storage_unavailable"}"#, status: 503)
        let backend = QuotioCLIBackend(session: stubSession())
        await backend.connect(.init(baseURL: URL(string: "http://127.0.0.1:43210")!, token: "test"))
        await backend.registerDetectedNativeAccounts()
        let discoveryNeedsAccess = await backend.accountStorageRequiresAuthorization()
        XCTAssertFalse(discoveryNeedsAccess)
        QuotioCLIURLProtocol.enqueue(#"{"error":"credential_storage_unavailable"}"#, status: 503)
        _ = await backend.accounts()
        let needsAccess = await backend.accountStorageRequiresAuthorization()
        XCTAssertTrue(needsAccess)

        QuotioCLIURLProtocol.enqueue(#"{"id":"authorize","status":"completed"}"#)
        QuotioCLIURLProtocol.enqueue(providers)
        QuotioCLIURLProtocol.enqueue(discovery)
        QuotioCLIURLProtocol.enqueue(#"{"id":"register","status":"completed"}"#)
        try await backend.authorizeAccountStorage()
        let stillNeedsAccess = await backend.accountStorageRequiresAuthorization()
        XCTAssertFalse(stillNeedsAccess)
        XCTAssertEqual(QuotioCLIURLProtocol.requests().filter { $0.url?.path == "/v1/account-vault/authorize" }.count, 1)
        XCTAssertEqual(QuotioCLIURLProtocol.requests().filter { $0.url?.path == "/v1/account-sources" }.count, 2)
    }

    func testStartupDiscoveryDoesNotTrustLastLaunchsScanMarker() async throws {
        let suite = "QuotioCLIBackendTests.startup.\(UUID().uuidString)"
        UserDefaults(suiteName: suite)?.set(["codex:codex_native"], forKey: "quotioCLI.knownNativeSources.v2")
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        QuotioCLIURLProtocol.enqueue(#"{"schema_version":1,"providers":[{"id":"codex","capabilities":{"source_references":[{"kind":"codex_native","platforms":["macos"],"origin":"borrowed_native"}]}}]}"#)
        QuotioCLIURLProtocol.enqueue(#"{"schema_version":1,"status":"checked","candidates":[{"status":"available","source":{"kind":"codex_native","location":"default"}}]}"#)
        QuotioCLIURLProtocol.enqueue(#"{"id":"register","status":"completed"}"#)
        let backend = QuotioCLIBackend(session: stubSession(), userDefaults: try XCTUnwrap(UserDefaults(suiteName: suite)))
        await backend.connect(.init(baseURL: URL(string: "http://127.0.0.1:43210")!, token: "test"))
        await backend.registerDetectedNativeAccounts()
        XCTAssertEqual(QuotioCLIURLProtocol.requests().map { $0.url!.path }, ["/v1/providers", "/v1/account-sources/discover", "/v1/account-sources"])
    }

    func testAuthorizationFailurePreservesItsVerifiedStage() async throws {
        let backend = QuotioCLIBackend(session: stubSession())
        await backend.connect(.init(baseURL: URL(string: "http://127.0.0.1:43210")!, token: "test"))
        for (code, expected) in [
            ("quotio_vault_access_failed", NativeSourceAuthorizationFailure.quotioVault),
            ("native_keychain_access_failed", .nativeKeychain),
            ("native_login_required", .nativeLogin),
            ("native_credential_invalid", .invalidCredential),
        ] {
            QuotioCLIURLProtocol.enqueue("{\"id\":\"authorize\",\"status\":\"failed\",\"error\":\"\(code)\"}")
            do {
                try await backend.authorizeNativeSource(.init(provider: .antigravity, kind: "antigravity_native", location: "gemini_keychain"))
                XCTFail("Expected a stage-specific failure")
            } catch let failure as NativeSourceAuthorizationFailure {
                XCTAssertEqual(failure, expected)
            }
        }
    }

    func testDisabledProviderDoesNotRefreshOrDiscoverAndAccountsRemainStored() async throws {
        let suite = "QuotioCLIBackendTests.tracking.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = UserDefaultsProviderTrackingPreferencesRepository(defaults: defaults)
        preferences.save(.init(disabledProviders: [.claude]))
        let backend = QuotioCLIBackend(session: stubSession(), trackingPreferences: preferences, userDefaults: UserDefaults(suiteName: suite)!)
        await backend.connect(QuotioHostConnection(baseURL: URL(string: "http://127.0.0.1:43210")!, token: "test"))
        _ = await backend.refresh(QuotaFetchRequest(provider: .claude, mode: .monitor))
        _ = await backend.refreshAll(mode: .monitor, providers: [.claude])
        await backend.rescanNativeAccounts(for: .claude)
        XCTAssertTrue(QuotioCLIURLProtocol.requests().isEmpty)

        QuotioCLIURLProtocol.enqueue(#"{"schema_version":1,"providers":[{"id":"claude","capabilities":{"source_references":[{"kind":"claude_native","platforms":["macos"],"origin":"borrowed_native"}]}}]}"#)
        await backend.registerDetectedNativeAccounts()
        XCTAssertEqual(QuotioCLIURLProtocol.requests().map { $0.url!.path }, ["/v1/providers"])
        QuotioCLIURLProtocol.enqueue(try hostFixture { root in
            var account = (root["accounts"] as! [[String: Any]])[0]
            account["id"] = "owned"; account["provider_id"] = "claude"
            var usage = (root["usage"] as! [[String: Any]])[0]
            usage["account_id"] = "owned"
            root["accounts"] = [account]; root["usage"] = [usage]
        })
        let accounts = await backend.accounts()
        XCTAssertEqual(accounts.map(\.id), ["owned"])

        preferences.save(.init())
        QuotioCLIURLProtocol.enqueue(#"{"id":"refresh","status":"completed"}"#)
        QuotioCLIURLProtocol.enqueue(#"{"schema_version":1,"generated_at":"2026-09-16T12:00:00Z","providers":[],"failures":[]}"#)
        _ = await backend.refresh(QuotaFetchRequest(provider: .claude, mode: .monitor))
        XCTAssertNotNil(QuotioCLIURLProtocol.body(forPath: "/v1/refresh"))
    }

    override func tearDown() {
        QuotioCLIURLProtocol.reset()
        super.tearDown()
    }

    func testUsageReportMapsCodexAnalyticsAndResetCredits() throws {
        let data = Data(#"""
        {
          "schema_version": 2,
          "host": {
            "id": "host-fixture",
            "platform": "macos",
            "api_versions": [
              1,
              2
            ],
            "capabilities": {
              "native_authorization": {
                "available": true,
                "reason": null
              }
            }
          },
          "revision": 7,
          "generated_at": "2026-09-24T00:00:00Z",
          "accounts": [
            {
              "id": "codex-account",
              "provider_id": "codex",
              "display_name": "Codex User",
              "user_label": null,
              "identity": {
                "evidence": "verified",
                "username": "fixture-user",
                "email": null
              },
              "enabled": true,
              "state": "ready",
              "sources": [
                {
                  "id": "codex-source",
                  "origin": "owned",
                  "kind": "owned_credential",
                  "location": "gh_keychain",
                  "enabled": true,
                  "selected": true,
                  "state": "ready",
                  "refresh_owner": "provider_tool",
                  "issue": null,
                  "actions": []
                }
              ],
              "actions": [
                {
                  "kind": "refresh",
                  "available": true,
                  "reason": null,
                  "interaction": "host"
                }
              ],
              "active": true
            }
          ],
          "usage": [
            {
              "account_id": "codex-account",
              "freshness": "fresh",
              "fetched_at": "2026-09-16T12:00:00Z",
              "expires_at": "2026-09-24T00:05:00Z",
              "plan": "plus",
              "metrics": [
                {
                  "id": "unlimited",
                  "display_name": "Unlimited",
                  "quota": {
                    "state": "unlimited"
                  },
                  "fetched_at": "2026-09-16T12:00:00Z",
                  "amounts": null,
                  "consumption": null,
                  "resets_at": null,
                  "reset_description": null,
                  "provenance": {
                    "source": "fixture",
                    "confidence": "exact"
                  }
                },
                {
                  "id": "disabled",
                  "display_name": "Disabled",
                  "quota": {
                    "state": "disabled"
                  },
                  "fetched_at": "2026-09-16T12:00:00Z",
                  "amounts": null,
                  "consumption": null,
                  "resets_at": null,
                  "reset_description": null,
                  "provenance": {
                    "source": "fixture",
                    "confidence": "exact"
                  }
                },
                {
                  "id": "limit",
                  "display_name": "Limit",
                  "quota": {
                    "state": "limit",
                    "amount": 5,
                    "unit": "USD"
                  },
                  "fetched_at": "2026-09-16T12:00:00Z",
                  "amounts": null,
                  "consumption": null,
                  "resets_at": null,
                  "reset_description": null,
                  "provenance": {
                    "source": "fixture",
                    "confidence": "exact"
                  }
                }
              ],
              "issue": null,
              "codex_profile": {
                "daily_usage": [
                  {
                    "date": "2026-09-15",
                    "tokens": 1200
                  }
                ],
                "latest_30_buckets_tokens": 1200,
                "lifetime_tokens": 8000,
                "peak_daily_tokens": 1200,
                "longest_running_turn_seconds": 3661,
                "current_streak_days": 1,
                "longest_streak_days": 3,
                "fetched_at": "2026-09-16T11:00:00Z"
              },
              "codex_reset_credits": {
                "available_count": 2,
                "credits": [
                  {
                    "id": "hashed-credit",
                    "expires_at": "2026-09-18T12:00:00Z"
                  }
                ],
                "fetched_at": "2026-09-16T11:30:00Z"
              }
            }
          ]
        }
        """#.utf8)

        let report = try QuotioHostSnapshot.decode(data)
        let quota = try XCTUnwrap(QuotioHostPresentationMapper.resolvedSnapshot(report).quotas[.codex]?["codex-account"])

        XCTAssertEqual(quota.lastUpdated, ISO8601DateFormatter().date(from: "2026-09-16T12:00:00Z"))
        XCTAssertEqual(quota.analytics?.rows.first { $0.id == "codex-lifetime-tokens" }?.value, "8K tokens")
        XCTAssertEqual(quota.analytics?.rows.first { $0.id == "codex-rate-limit-resets" }?.value, "2 available")
        XCTAssertNotNil(quota.analytics?.rows.first { $0.id == "codex-rate-limit-reset-hashed-credit" })

        var repository = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { repository.deleteLastPathComponent() }
        let catalog = try Data(contentsOf: repository.appendingPathComponent("apps/macos/Quotio/Localizable.xcstrings"))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: catalog) as? [String: Any])
        let strings = try XCTUnwrap(json["strings"] as? [String: [String: Any]])
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let localizedDirectory = directory.appendingPathComponent("fr.lproj")
        try FileManager.default.createDirectory(at: localizedDirectory, withIntermediateDirectories: true)
        var translations: [String: String] = [:]
        for (key, entry) in strings {
            guard let locales = entry["localizations"] as? [String: [String: Any]] else { continue }
            if key.hasPrefix("quota.analytics.") || key == "quota.metric.unlimited" {
                XCTAssertEqual(Set(locales.keys), ["en", "fr", "vi", "zh-Hans"], key)
            }
            if let unit = locales["fr"]?["stringUnit"] as? [String: String] {
                translations[key] = unit["value"]
            }
        }
        let localizedData = try PropertyListSerialization.data(fromPropertyList: translations, format: .xml, options: 0)
        try localizedData.write(to: localizedDirectory.appendingPathComponent("Localizable.strings"))
        let bundle = try XCTUnwrap(Bundle(path: localizedDirectory.path))
        let localized = try XCTUnwrap(QuotioHostPresentationMapper.resolvedSnapshot(report, bundle: bundle, locale: Locale(identifier: "fr")).quotas[.codex]?["codex-account"])
        XCTAssertEqual(localized.analytics?.rows.first { $0.id == "today" }?.title, "Aujourd’hui")
        XCTAssertEqual(localized.analytics?.rows.first { $0.id == "today" }?.value, "Aucune donnée")
        XCTAssertEqual(localized.analytics?.rows.first { $0.id == "codex-longest-task" }?.value, "1 h 1 min")
        XCTAssertEqual(localized.analytics?.rows.first { $0.id == "codex-current-streak" }?.value, "1 jour")
        XCTAssertEqual(localized.analytics?.rows.first { $0.id == "codex-rate-limit-resets" }?.value, "2 disponibles")
        XCTAssertTrue(localized.analytics?.rows.first { $0.id == "codex-rate-limit-reset-hashed-credit" }?.value.hasPrefix("dans ") == true)
        XCTAssertEqual(localized.models[0].presentation, .status(text: "Illimité"))
        XCTAssertEqual(localized.models[1].presentation, .status(text: "Désactivé"))
        XCTAssertEqual(localized.models[2].presentation, .status(text: "Plafond de 5 USD"))
    }

    func testAccountCreateUsesBearerAndIdempotencyHeaders() async throws {
        QuotioCLIURLProtocol.enqueue(#"{"id":"operation-1","status":"completed","error":null}"#)
        let backend = QuotioCLIBackend(session: stubSession())
        await backend.connect(QuotioHostConnection(
            baseURL: URL(string: "http://127.0.0.1:43210")!,
            token: "private-token"
        ))

        try await backend.saveAPIKey(
            providerID: AccountProviderID(rawValue: QuotaProvider.openRouter.rawValue),
            label: "Primary",
            apiKey: "secret",
            existingAccountID: nil
        )

        let request = try XCTUnwrap(QuotioCLIURLProtocol.requests().first)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.path, "/v2/accounts")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer private-token")
        XCTAssertNotNil(request.value(forHTTPHeaderField: "Idempotency-Key"))
    }

    func testNativeDiscoveryRetriesFailedRegistrationWithinLaunch() async throws {
        let suite = "QuotioCLIBackendTests.nativeDiscovery.\(UUID().uuidString)"
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let providers = #"{"schema_version":1,"providers":[{"id":"codex","capabilities":{"source_references":[{"kind":"codex_native","platforms":["macos"],"origin":"borrowed_native"},{"kind":"cli_proxy_auth_file","platforms":["macos"],"origin":"borrowed_proxy"}]}},{"id":"cursor","capabilities":{"source_references":[{"kind":"cursor_native","platforms":["macos"],"origin":"borrowed_native"}]}},{"id":"amp","capabilities":{"source_references":[{"kind":"amp_native","platforms":["linux"],"origin":"borrowed_native"}]}},{"id":"grok","capabilities":{"source_references":[{"kind":"grok_native","platforms":["macos","linux"],"origin":"borrowed_native"}]}}]}"#
        QuotioCLIURLProtocol.enqueue(providers)
        QuotioCLIURLProtocol.enqueue(#"{"schema_version":1,"status":"checked","candidates":[{"label":"Native source","status":"available","source":{"kind":"codex_native","location":"default"}}]}"#)
        QuotioCLIURLProtocol.enqueue(#"{"id":"codex-source","status":"completed"}"#)
        QuotioCLIURLProtocol.enqueue(#"{"schema_version":1,"status":"permission_required","candidates":[{"label":"Native source","status":"permission_required","source":{"kind":"cursor_native"}}]}"#)
        QuotioCLIURLProtocol.enqueue(#"{"schema_version":1,"status":"checked","candidates":[{"label":"Native entry 1","status":"available","source":{"kind":"discovered","discovery_ref":"opaque-reference"}}]}"#)
        QuotioCLIURLProtocol.enqueue(#"{"id":"grok-source","status":"failed","error":"duplicate_account"}"#)
        QuotioCLIURLProtocol.enqueue(providers)
        QuotioCLIURLProtocol.enqueue(#"{"schema_version":1,"status":"checked","candidates":[{"status":"available","source":{"kind":"discovered","discovery_ref":"retry-reference"}}]}"#)
        QuotioCLIURLProtocol.enqueue(#"{"id":"grok-retry","status":"completed"}"#)
        let backend = QuotioCLIBackend(
            session: stubSession(),
            userDefaults: try XCTUnwrap(UserDefaults(suiteName: suite))
        )
        await backend.connect(QuotioHostConnection(
            baseURL: URL(string: "http://127.0.0.1:43210")!, token: "private-token"
        ))

        await backend.registerDetectedNativeAccounts()
        await backend.registerDetectedNativeAccounts()

        let requests = QuotioCLIURLProtocol.requests()
        XCTAssertEqual(requests.filter { $0.url?.path == "/v1/providers" }.count, 2)
        XCTAssertEqual(requests.filter { $0.url?.path == "/v1/account-sources/discover" }.count, 4)
        XCTAssertEqual(requests.filter { $0.url?.path == "/v1/account-sources" }.count, 3)
        XCTAssertFalse(requests.contains { $0.httpMethod == "PATCH" })
        let discoveryBodies = try QuotioCLIURLProtocol.bodies(forPath: "/v1/account-sources/discover")
            .map { try XCTUnwrap(JSONSerialization.jsonObject(with: $0) as? [String: Any]) }
        XCTAssertTrue(discoveryBodies.allSatisfy { $0["inspect"] as? Bool == true })
    }

    func testNativeDiscoveryContinuesAfterOneCandidateFailsAndRetriesTheKind() async throws {
        let suite = "QuotioCLIBackendTests.partialDiscovery." + UUID().uuidString
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let providers = #"{"schema_version":1,"providers":[{"id":"codex","capabilities":{"source_references":[{"kind":"codex_native","platforms":["macos"],"origin":"borrowed_native"}]}}]}"#
        let discovery = #"{"schema_version":1,"status":"checked","candidates":[{"status":"available","source":{"kind":"codex_native","location":"default"}},{"status":"available","source":{"kind":"codex_native","location":"config"}}]}"#
        let backend = QuotioCLIBackend(session: stubSession(), userDefaults: try XCTUnwrap(UserDefaults(suiteName: suite)))
        await backend.connect(.init(baseURL: URL(string: "http://127.0.0.1:43210")!, token: "test"))

        QuotioCLIURLProtocol.enqueue(providers)
        QuotioCLIURLProtocol.enqueue(discovery)
        QuotioCLIURLProtocol.enqueue(#"{"id":"first","status":"failed","error":"credential_validation_failed"}"#)
        QuotioCLIURLProtocol.enqueue(#"{"id":"second","status":"completed"}"#)
        await backend.registerDetectedNativeAccounts()
        let bodies = try QuotioCLIURLProtocol.bodies(forPath: "/v1/account-sources")
            .map { try XCTUnwrap(JSONSerialization.jsonObject(with: $0) as? [String: Any]) }
        XCTAssertEqual(bodies.compactMap { $0["location"] as? String }, ["default", "config"])

        QuotioCLIURLProtocol.reset()
        QuotioCLIURLProtocol.enqueue(providers)
        QuotioCLIURLProtocol.enqueue(discovery)
        QuotioCLIURLProtocol.enqueue(#"{"id":"first-retry","status":"completed"}"#)
        QuotioCLIURLProtocol.enqueue(#"{"id":"second-retry","status":"completed"}"#)
        await backend.registerDetectedNativeAccounts()
        XCTAssertEqual(QuotioCLIURLProtocol.bodies(forPath: "/v1/account-sources").count, 2)
        XCTAssertFalse(QuotioCLIURLProtocol.requests().contains { $0.url?.path.hasSuffix("/authorize") == true })
    }

    func testExplicitRescanRetriesOnlyRequestedKnownProviderWithoutEnablingAccounts() async throws {
        let suite = "QuotioCLIBackendTests.rescan." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(["kiro:kiro_native", "codex:codex_native"], forKey: "quotioCLI.knownNativeSources.v2")
        QuotioCLIURLProtocol.enqueue(#"{"schema_version":1,"providers":[{"id":"kiro","capabilities":{"source_references":[{"kind":"kiro_native","platforms":["macos"],"origin":"borrowed_native"}]}},{"id":"codex","capabilities":{"source_references":[{"kind":"codex_native","platforms":["macos"],"origin":"borrowed_native"}]}}]}"#)
        QuotioCLIURLProtocol.enqueue(#"{"schema_version":1,"status":"checked","candidates":[{"status":"available","source":{"kind":"kiro_native"}}]}"#)
        QuotioCLIURLProtocol.enqueue(#"{"id":"existing","status":"failed","error":"duplicate_account"}"#)
        let backend = QuotioCLIBackend(session: stubSession(), userDefaults: try XCTUnwrap(UserDefaults(suiteName: suite)))
        await backend.connect(QuotioHostConnection(baseURL: URL(string: "http://127.0.0.1:43210")!, token: "test"))

        await backend.rescanNativeAccounts(for: .kiro)

        let bodies = QuotioCLIURLProtocol.bodies(forPath: "/v1/account-sources/discover")
        XCTAssertEqual(bodies.count, 1)
        let body = try XCTUnwrap(JSONSerialization.jsonObject(with: bodies[0]) as? [String: Any])
        XCTAssertEqual(body["provider"] as? String, "kiro")
        XCTAssertEqual(body["inspect"] as? Bool, true)
        XCTAssertFalse(QuotioCLIURLProtocol.requests().contains { $0.httpMethod == "PATCH" })
        XCTAssertEqual(Set(defaults.stringArray(forKey: "quotioCLI.knownNativeSources.v2") ?? []),
                       ["kiro:kiro_native", "codex:codex_native"])
    }

    func testNativePermissionWaitsForExplicitAuthorization() async throws {
        let suite = "QuotioCLIBackendTests.nativePermission.\(UUID().uuidString)"
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        QuotioCLIURLProtocol.enqueue(#"{"schema_version":1,"providers":[{"id":"factory","capabilities":{"source_references":[{"kind":"factory_native","platforms":["macos"],"origin":"borrowed_native"}]}}]}"#)
        QuotioCLIURLProtocol.enqueue(#"{"schema_version":1,"status":"permission_required","candidates":[{"label":"Native source","status":"permission_required","source":{"kind":"factory_native","location":"v2_keyring"}}]}"#)
        QuotioCLIURLProtocol.enqueue(#"{"schema_version":1,"accounts":[]}"#)
        QuotioCLIURLProtocol.enqueue(#"{"id":"factory-source","status":"completed"}"#)
        QuotioCLIURLProtocol.enqueue(#"{"schema_version":1,"providers":[]}"#)
        let backend = QuotioCLIBackend(
            session: stubSession(),
            userDefaults: try XCTUnwrap(UserDefaults(suiteName: suite))
        )
        await backend.connect(QuotioHostConnection(
            baseURL: URL(string: "http://127.0.0.1:43210")!, token: "private-token"
        ))

        await backend.registerDetectedNativeAccounts()
        XCTAssertFalse(QuotioCLIURLProtocol.requests().contains {
            $0.url?.path == "/v1/account-sources"
        })
        let permissions = await backend.nativeSourcesRequiringPermission()
        let permission = try XCTUnwrap(permissions.first)
        XCTAssertEqual(permission.provider, .factoryDroid)
        XCTAssertEqual(permission.location, "v2_keyring")

        try await backend.authorizeNativeSource(permission)
        XCTAssertEqual(QuotioCLIURLProtocol.requests().filter {
            $0.url?.path == "/v1/account-sources/authorize"
        }.count, 1)
    }

    func testNativePermissionStaysHiddenForDisabledRegisteredSource() async throws {
        let suite = "QuotioCLIBackendTests.disabledNativePermission.\(UUID().uuidString)"
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        QuotioCLIURLProtocol.enqueue(#"{"schema_version":1,"providers":[{"id":"factory","capabilities":{"source_references":[{"kind":"factory_native","platforms":["macos"],"origin":"borrowed_native"}]}}]}"#)
        QuotioCLIURLProtocol.enqueue(#"{"schema_version":1,"status":"permission_required","candidates":[{"label":"Native source","status":"permission_required","source":{"kind":"factory_native","location":"v2_keyring"}}]}"#)
        QuotioCLIURLProtocol.enqueue(#"{"schema_version":1,"accounts":[{"id":"factory-disabled","provider":"factory","label":"Factory","origin":"borrowed_native","active":true,"enabled":false,"source_kind":"factory_native","source_location":"v2_keyring","source_id":null}]}"#)
        let backend = QuotioCLIBackend(
            session: stubSession(),
            userDefaults: try XCTUnwrap(UserDefaults(suiteName: suite))
        )
        await backend.connect(QuotioHostConnection(
            baseURL: URL(string: "http://127.0.0.1:43210")!, token: "private-token"
        ))

        await backend.registerDetectedNativeAccounts()
        let permissions = await backend.nativeSourcesRequiringPermission()
        XCTAssertTrue(permissions.isEmpty)
    }

    func testRegisteredNativeFileDoesNotHideAnotherLocationsPermissionAcrossRelaunch() async throws {
        let suite = "QuotioCLIBackendTests.nativeLocations." + UUID().uuidString
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let pending = NativeSourcePermission(provider: .factoryDroid, kind: "factory_native", location: "v2_keyring")
        UserDefaults(suiteName: suite)?.set(try JSONEncoder().encode([pending]), forKey: "quotioCLI.pendingNativeSources.v1")
        for _ in 0..<2 {
            let backend = QuotioCLIBackend(session: stubSession(), userDefaults: try XCTUnwrap(UserDefaults(suiteName: suite)))
            await backend.connect(.init(baseURL: URL(string: "http://127.0.0.1:43210")!, token: "test"))
            QuotioCLIURLProtocol.enqueue(#"{"schema_version":1,"accounts":[{"id":"factory-file","provider":"factory","label":"Factory","origin":"borrowed_native","enabled":true,"source_kind":"factory_native","source_location":"v2_file"}]}"#)
            let permissions = await backend.nativeSourcesRequiringPermission()
            XCTAssertEqual(permissions, [pending])
        }
        XCTAssertEqual(QuotioCLIURLProtocol.requests().map { $0.url!.path }, ["/v1/accounts", "/v1/accounts"])
    }

    func testLegacyImportUsesStableReceiptAndUnixExpiry() async throws {
        let backend = QuotioCLIBackend(session: stubSession())
        await backend.connect(QuotioHostConnection(baseURL: URL(string: "http://127.0.0.1:43210")!, token: "private-token"))
        let account = Account.make(providerID: AccountProviderID(rawValue: "kiro"), accountKey: "Work", source: .quotioKeychain)
        let credential = StoredCredential(accessToken: "synthetic-access", refreshToken: "synthetic-refresh", idToken: nil, accountID: "user", expiresAt: Date(timeIntervalSince1970: 1_700_000_000.9), extra: ["authMethod": "IdC", "clientId": "synthetic-client", "clientSecret": "synthetic-secret"])
        for _ in 0..<2 {
            QuotioCLIURLProtocol.enqueue(#"{"id":"import","status":"completed"}"#)
            try await backend.importLegacyAccount(account, credential: credential, disabled: true)
        }
        let requests = QuotioCLIURLProtocol.requests()
        XCTAssertEqual(requests.count, 2)
        XCTAssertEqual(requests[0].value(forHTTPHeaderField: "Idempotency-Key"), requests[1].value(forHTTPHeaderField: "Idempotency-Key"))
        let body = try XCTUnwrap(QuotioCLIURLProtocol.body(forPath: "/v1/accounts/migrate"))
        let value = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(value["enabled"] as? Bool, false)
        XCTAssertEqual(value["provider"] as? String, "kiro")
        let imported = try XCTUnwrap(value["credential"] as? [String: Any])
        XCTAssertEqual(imported["expires_at"] as? Int64, 1_700_000_000)
        XCTAssertEqual((imported["extra"] as? [String: String])?["clientSecret"], "synthetic-secret")
    }

    func testLegacyImportRejectsOutOfRangeExpiryWithoutSendingCredential() async throws {
        let backend = QuotioCLIBackend(session: stubSession())
        await backend.connect(QuotioHostConnection(baseURL: URL(string: "http://127.0.0.1:43210")!, token: "private-token"))
        let account = Account.make(providerID: AccountProviderID(rawValue: "claude"), accountKey: "Work", source: .quotioKeychain)
        let credential = StoredCredential(accessToken: "synthetic", refreshToken: "synthetic-refresh", idToken: nil, accountID: "user", expiresAt: Date(timeIntervalSince1970: 1e100), extra: [:])
        do {
            try await backend.importLegacyAccount(account, credential: credential, disabled: false)
            XCTFail("Invalid dates must be reported without trapping")
        } catch { }
        XCTAssertTrue(QuotioCLIURLProtocol.requests().isEmpty)
    }

    func testSynchronizeWarpTokensOnlyUpdatesAndRemovesMirroredAccounts() async throws {
        QuotioCLIURLProtocol.enqueue(#"{"schema_version":1,"accounts":[{"id":"monitor","provider":"warp","label":"Monitor","origin":"owned","enabled":true,"source_kind":null},{"id":"warp-1","provider":"warp","label":"__quotio_local_warp__:Work","origin":"owned","enabled":true,"source_kind":null},{"id":"warp-2","provider":"warp","label":"__quotio_local_warp__:Old","origin":"owned","enabled":true,"source_kind":null}]}"#)
        QuotioCLIURLProtocol.enqueue(#"{"id":"operation-1","status":"completed","error":null}"#)
        QuotioCLIURLProtocol.enqueue(#"{"id":"operation-2","status":"completed","error":null}"#)
        let backend = QuotioCLIBackend(session: stubSession())
        await backend.connect(QuotioHostConnection(
            baseURL: URL(string: "http://127.0.0.1:43210")!,
            token: "private-token"
        ))

        try await backend.synchronizeWarpTokens([WarpToken(name: "Work", token: "new-token")])

        let requests = QuotioCLIURLProtocol.requests()
        XCTAssertEqual(requests.map(\.httpMethod), ["GET", "PATCH", "DELETE"])
        XCTAssertEqual(requests.map { $0.url?.path }, ["/v1/accounts", "/v1/accounts/warp-1", "/v1/accounts/warp-2"])
    }

    func testDeviceCodeExpiryComesFromHostStateAndCleansUpTheSession() async throws {
        let expired = Int64(Date().timeIntervalSince1970) + 3600
        QuotioCLIURLProtocol.enqueue(#"{"provider":"copilot","workflow":"device_code","user_code":"CODE","id":"session-1","url":"https://github.com/login/device","expires_at":\#(expired),"status":"waiting","account_id":null,"error_code":null}"#)
        QuotioCLIURLProtocol.enqueue(#"{"provider":"copilot","workflow":"device_code","user_code":"CODE","id":"session-1","url":"https://github.com/login/device","expires_at":\#(expired),"status":"expired","account_id":null,"error_code":null}"#)
        QuotioCLIURLProtocol.enqueue(#"{"provider":"copilot","workflow":"device_code","user_code":"CODE","id":"session-1","url":"https://github.com/login/device","expires_at":\#(expired),"status":"expired","account_id":null,"error_code":null}"#)
        let backend = QuotioCLIBackend(session: stubSession())
        await backend.connect(QuotioHostConnection(
            baseURL: URL(string: "http://127.0.0.1:43210")!,
            token: "private-token"
        ))
        let authorizer = QuotioCLIOAuthAuthorizer(
            backend: backend,
            urlOpener: QuotioCLIURLOpenerStub()
        )

        do {
            _ = try await authorizer.begin(
                request: OAuthAuthorizationRequest(
                    providerID: AccountProviderID(rawValue: QuotaProvider.copilot.rawValue)
                ),
                attemptID: OAuthAttemptID(),
                progress: { _ in }
            )
            XCTFail("Expected the provider deadline to expire the session")
        } catch {
            XCTAssertEqual(error as? OAuthFlowFailure, .expired)
        }
        XCTAssertEqual(QuotioCLIURLProtocol.requests().count, 3)
        XCTAssertEqual(QuotioCLIURLProtocol.requests().last?.httpMethod, "DELETE")
    }

    func testOAuthCallbackUsesExchangeTimeout() async throws {
        QuotioCLIURLProtocol.enqueue(#"{"provider":"codex","workflow":"browser_redirect","user_code":null,"id":"session-1","url":"https://example.com","expires_at":4102444800,"status":"completed","account_id":"account-1","error_code":null}"#)
        let backend = QuotioCLIBackend(session: stubSession())
        await backend.connect(QuotioHostConnection(
            baseURL: URL(string: "http://127.0.0.1:43210")!,
            token: "private-token"
        ))

        _ = try await backend.completeOAuth(id: "session-1", code: "code")

        XCTAssertEqual(QuotioCLIURLProtocol.requests().first?.timeoutInterval, 60)
    }

    func testBrowserOAuthUsesHostListenerAndReturnsBackendAccountMetadata() async throws {
        let waiting = #"{"provider":"codex","workflow":"browser_callback","id":"session","url":"https://auth.example.test/authorize","expires_at":4102444800,"status":"waiting"}"#
        QuotioCLIURLProtocol.enqueue(waiting)
        QuotioCLIURLProtocol.enqueue(#"{"provider":"codex","workflow":"browser_callback","id":"session","url":"https://auth.example.test/authorize","expires_at":4102444800,"status":"completed","account_id":"source-a"}"#)
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("../../../../").standardizedFileURL
        let data = try Data(contentsOf: root.appendingPathComponent("apps/cli/tests/fixtures/contracts/accounts-v2.json"))
        let envelope = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        var account = (envelope["accounts"] as! [[String: Any]])[0]
        account["provider_id"] = "codex"; account["display_name"] = "Backend account name"
        QuotioCLIURLProtocol.enqueue(try XCTUnwrap(String(data: JSONSerialization.data(withJSONObject: account), encoding: .utf8)))
        let backend = QuotioCLIBackend(session: stubSession())
        await backend.connect(.init(baseURL: URL(string: "http://127.0.0.1:43210")!, token: "test"))
        let authorizer = QuotioCLIOAuthAuthorizer(backend: backend, urlOpener: QuotioCLIURLOpenerStub())
        let outcome = try await authorizer.begin(request: .init(providerID: .init(rawValue: "codex")), attemptID: .init(), progress: { _ in })
        guard case .completed(let result) = outcome else { return XCTFail("Expected completion") }
        XCTAssertEqual(result.id, "source-a")
        XCTAssertEqual(result.displayName, "Backend account name")
        let requests = QuotioCLIURLProtocol.requests()
        XCTAssertEqual(requests.map { $0.url?.path }, ["/v1/auth/sessions", "/v1/auth/sessions/session", "/v2/accounts/source-a"])
        let body = try XCTUnwrap(QuotioCLIURLProtocol.body(forPath: "/v1/auth/sessions"))
        let input = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: String])
        XCTAssertEqual(input, ["provider":"codex"])
    }

    private func hostFixture(_ edit: (inout [String: Any]) -> Void = { _ in }) throws -> String {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("../../../../").standardizedFileURL
        let data = try Data(contentsOf: root.appendingPathComponent("apps/cli/tests/fixtures/contracts/snapshot-v2.json"))
        var value = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        edit(&value)
        return try XCTUnwrap(String(data: JSONSerialization.data(withJSONObject: value), encoding: .utf8))
    }

    func testSnapshotReadPreservesRustNamesGroupsMetricsAndSourceSelection() async throws {
        let fixture = try hostFixture()
        QuotioCLIURLProtocol.enqueue(fixture)
        QuotioCLIURLProtocol.enqueue(fixture)
        let backend = QuotioCLIBackend(session: stubSession())
        await backend.connect(.init(baseURL: URL(string: "http://127.0.0.1:43210")!, token: "test"))
        let snapshot = await backend.bootstrap(mode: .monitor)
        let accounts = await backend.accounts()
        XCTAssertEqual(accounts.map(\.id), ["copilot-account", "devin-desktop-account"])
        XCTAssertEqual(accounts.map(\.displayName), ["fixture-user", "person@example.test"])
        XCTAssertEqual(accounts[1].sources.count, 2)
        XCTAssertEqual(snapshot.accountIDs[.devin]?["devin-desktop-account"], "devin-desktop-source-0")
        XCTAssertEqual(snapshot.quotas[.devin]?["devin-desktop-account"]?.models.first?.percentage, 75)
        XCTAssertEqual(snapshot.quotas[.devin]?["devin-desktop-account"]?.models.first?.id, "weekly")
        XCTAssertEqual(snapshot.quotas[.copilot]?["copilot-account"]?.planType, "Business")
        XCTAssertTrue(snapshot.quotas[.copilot]?["copilot-account"]?.models.isEmpty == true)
        XCTAssertEqual(QuotioCLIURLProtocol.requests().map { $0.url?.path }, ["/v2/snapshot", "/v2/snapshot"])
    }

    func testSnapshotDoesNotMergeEqualDisplayNamesOrRecomputeFreshness() async throws {
        let fixture = try hostFixture { root in
            var accounts = root["accounts"] as! [[String: Any]]
            accounts[1]["provider_id"] = "copilot"
            accounts[1]["display_name"] = "fixture-user"
            root["accounts"] = accounts
            var usage = root["usage"] as! [[String: Any]]
            usage[0]["freshness"] = "stale"
            usage[1]["freshness"] = "fresh"
            usage[1]["fetched_at"] = "2000-01-01T00:00:00Z"
            root["usage"] = usage
        }
        let host = try QuotioHostSnapshot.decode(Data(fixture.utf8))
        let snapshot = QuotioHostPresentationMapper.resolvedSnapshot(host)
        XCTAssertEqual(snapshot.quotas[.copilot]?.count, 2)
        XCTAssertEqual(snapshot.accountStates[.init(provider: .copilot, accountKey: "copilot-account")]?.quota, .stale)
        XCTAssertEqual(snapshot.accountStates[.init(provider: .copilot, accountKey: "devin-desktop-account")]?.quota, .fresh)
    }

    func testOlderRevisionCannotReplaceNewerHostStateAndReconnectClearsIt() async throws {
        let backend = QuotioCLIBackend(session: stubSession())
        await backend.connect(.init(baseURL: URL(string: "http://127.0.0.1:43210")!, token: "test"))
        QuotioCLIURLProtocol.enqueue(try hostFixture())
        _ = await backend.bootstrap(mode: .monitor)
        QuotioCLIURLProtocol.enqueue(try hostFixture { root in
            root["revision"] = 6; root["accounts"] = []; root["usage"] = []
        })
        let retained = await backend.accounts()
        XCTAssertEqual(retained.count, 2)
        await backend.connect(.init(baseURL: URL(string: "http://127.0.0.1:43211")!, token: "second"))
        QuotioCLIURLProtocol.enqueue(try hostFixture { root in
            root["revision"] = 1; root["accounts"] = []; root["usage"] = []
            var host = root["host"] as! [String: Any]; host["id"] = "another-host"; root["host"] = host
        })
        let replaced = await backend.accounts()
        XCTAssertTrue(replaced.isEmpty)
    }

    func testRefreshUsesLogicalIDAndAcceptsTheFullHostSnapshot() async throws {
        let fixture = try hostFixture()
        QuotioCLIURLProtocol.enqueue(fixture)
        QuotioCLIURLProtocol.enqueue(#"{"id":"refresh","status":"completed"}"#)
        QuotioCLIURLProtocol.enqueue(fixture)
        let backend = QuotioCLIBackend(session: stubSession())
        await backend.connect(.init(baseURL: URL(string: "http://127.0.0.1:43210")!, token: "test"))
        _ = await backend.bootstrap(mode: .monitor)
        let result = await backend.refresh(.init(provider: .devin, scope: .account("devin-desktop-account"), mode: .monitor))
        let body = try XCTUnwrap(QuotioCLIURLProtocol.body(forPath: "/v1/refresh"))
        let request = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(request["account_id"] as? String, "devin-desktop-account")
        XCTAssertNotNil(result.quotas[.copilot]?["copilot-account"])
        XCTAssertNotNil(result.quotas[.devin]?["devin-desktop-account"])
    }

    func testFailedProbeKeepsProviderIssueWithoutInventingAccounts() async throws {
        let fixture = try hostFixture { root in
            root["accounts"] = []; root["usage"] = []
            root["provider_issues"] = ["claude": ["code": "authentication", "retryable": false, "action": NSNull()]]
        }
        QuotioCLIURLProtocol.enqueue(fixture); QuotioCLIURLProtocol.enqueue(fixture)
        let backend = QuotioCLIBackend(session: stubSession())
        await backend.connect(.init(baseURL: URL(string: "http://127.0.0.1:43210")!, token: "test"))
        let snapshot = await backend.bootstrap(mode: .monitor)
        let accounts = await backend.accounts()
        XCTAssertTrue(accounts.isEmpty)
        XCTAssertEqual(snapshot.issues[.claude]?.reason, .authentication)
    }

    func testHostDisabledStateAndActionsAreNotInferredFromSourceKind() async throws {
        let fixture = try hostFixture { root in
            var accounts = root["accounts"] as! [[String: Any]]
            accounts[0]["enabled"] = false; accounts[0]["state"] = "disabled"
            accounts[0]["actions"] = [["kind":"remove", "available":true, "reason":NSNull(), "interaction":"host"]]
            var sources = accounts[0]["sources"] as! [[String: Any]]
            sources[0]["enabled"] = false; sources[0]["selected"] = false; sources[0]["state"] = "disabled"
            accounts[0]["sources"] = sources; root["accounts"] = accounts
        }
        QuotioCLIURLProtocol.enqueue(fixture)
        let backend = QuotioCLIBackend(session: stubSession())
        await backend.connect(.init(baseURL: URL(string: "http://127.0.0.1:43210")!, token: "test"))
        let accounts = await backend.accounts()
        XCTAssertTrue(accounts[0].isDisabled)
        XCTAssertEqual(accounts[0].capabilities, [.delete])
        XCTAssertTrue(accounts[1].capabilities.isEmpty)
    }

    func testUnchangedSnapshotDoesNotPublishAnAccountReloadLoop() async throws {
        let backend = QuotioCLIBackend(session: stubSession())
        await backend.connect(.init(baseURL: URL(string: "http://127.0.0.1:43210")!, token: "test"))
        let states = await backend.states()
        QuotioCLIURLProtocol.enqueue(try hostFixture())
        _ = await backend.bootstrap(mode: .monitor)
        QuotioCLIURLProtocol.enqueue(try hostFixture { $0["generated_at"] = "2026-09-24T00:00:01Z" })
        _ = await backend.accounts()
        QuotioCLIURLProtocol.enqueue(try hostFixture { root in
            root["revision"] = 8
            var accounts = root["accounts"] as! [[String: Any]]
            accounts[0]["display_name"] = "New host name"
            root["accounts"] = accounts
        })
        _ = await backend.accounts()
        await backend.cancelForTermination()
        var received: [QuotaSnapshot] = []
        for await state in states { received.append(state) }
        XCTAssertEqual(received.count, 3)
        XCTAssertEqual(received.last?.quotas[.copilot]?["copilot-account"]?.accountDisplayName, "New host name")
    }

    func testAPIKeyEditTargetsItsSourceWithoutOverridingHostNaming() async throws {
        QuotioCLIURLProtocol.enqueue(try hostFixture { root in
            var account = (root["accounts"] as! [[String: Any]])[0]
            account["id"] = "logical"; account["provider_id"] = "amp"
            var sources = account["sources"] as! [[String: Any]]
            sources[0]["origin"] = "owned"; sources[0]["kind"] = "owned_credential"
            sources[0]["actions"] = [["kind":"replace_api_key", "available":true, "reason":NSNull(), "interaction":"host"]]
            account["sources"] = sources; root["accounts"] = [account]; root["usage"] = []
        })
        QuotioCLIURLProtocol.enqueue(#"{"id":"replace","status":"completed","result":{"account_id":"new-logical"}}"#)
        let backend = QuotioCLIBackend(session: stubSession())
        await backend.connect(.init(baseURL: URL(string: "http://127.0.0.1:43210")!, token: "test"))
        try await backend.saveAPIKey(providerID: .init(rawValue: "amp"), label: "Work", apiKey: "synthetic-key", existingAccountID: "logical")
        XCTAssertEqual(QuotioCLIURLProtocol.requests().map { $0.url?.path }, ["/v2/snapshot", "/v2/sources/copilot-source-0"])
        let body = try XCTUnwrap(QuotioCLIURLProtocol.body(forPath: "/v2/sources/copilot-source-0"))
        let update = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: String])
        XCTAssertEqual(update, ["api_key": "synthetic-key"])
    }

    func testRecoveryActionComesFromTheHostEvenForUnknownReasons() throws {
        for available in [true, false] {
            let fixture = try hostFixture { root in
                var usage = root["usage"] as! [[String: Any]]
                usage[0]["issue"] = ["code":"future_provider_error", "retryable":true,
                    "action":["kind":"retry", "available":available, "reason":NSNull(), "interaction":"host"]]
                root["usage"] = usage
            }
            let host = try QuotioHostSnapshot.decode(Data(fixture.utf8))
            let snapshot = QuotioHostPresentationMapper.resolvedSnapshot(host)
            let issue = snapshot.accountIssues[.init(provider: .copilot, accountKey: "copilot-account")]
            XCTAssertNil(issue?.reason)
            XCTAssertEqual(issue?.recoveryAction, available ? .retry : nil)
        }
    }

    func testNewUnitsRenderWithoutProviderRulesAndUnknownQuotaKindsStayUnsupported() throws {
        for state in ["unknown", "future_quota_kind"] {
            let fixture = try hostFixture { root in
                var usage = root["usage"] as! [[String: Any]]
                var metrics = usage[1]["metrics"] as! [[String: Any]]
                metrics[0]["quota"] = ["state":state]
                metrics[0]["amounts"] = ["remaining":42, "limit":NSNull(), "unit":"widgets"]
                usage[1]["metrics"] = metrics; root["usage"] = usage
            }
            let host = try QuotioHostSnapshot.decode(Data(fixture.utf8))
            let snapshot = QuotioHostPresentationMapper.resolvedSnapshot(host)
            let metric = try XCTUnwrap(snapshot.quotas[.devin]?["devin-desktop-account"]?.models.first)
            if state == "unknown" {
                XCTAssertEqual(metric.presentation, .amount(value: 42, unit: try XCTUnwrap(QuotaMetricUnit(rawValue: "widgets")), semantics: .balance))
            } else {
                XCTAssertEqual(metric.presentation, .status(text: "Unsupported"))
            }
        }
    }

    func testOwnerDisabledHealthDoesNotChangeTheHostEnabledFlag() async throws {
        QuotioCLIURLProtocol.enqueue(try hostFixture { root in
            var accounts = root["accounts"] as! [[String: Any]]
            accounts[0]["state"] = "disabled"
            var sources = accounts[0]["sources"] as! [[String: Any]]
            sources[0]["state"] = "disabled"; sources[0]["selected"] = false
            accounts[0]["sources"] = sources; root["accounts"] = accounts
            var usage = root["usage"] as! [[String: Any]]
            usage[0]["freshness"] = "unavailable"
            usage[0]["issue"] = ["code":"source_disabled", "retryable":false, "action":NSNull()]
            root["usage"] = usage
        })
        let backend = QuotioCLIBackend(session: stubSession())
        await backend.connect(.init(baseURL: URL(string: "http://127.0.0.1:43210")!, token: "test"))
        let accounts = await backend.accounts()
        XCTAssertEqual(accounts[0].status, .disabled)
        XCTAssertFalse(accounts[0].isDisabled)
        XCTAssertTrue(accounts[0].enabled)
    }

    func testDisplayedConsumptionUsesTheHostValueInsteadOfSubtractingBalance() throws {
        let fixture = try hostFixture { root in
            var usage = root["usage"] as! [[String: Any]]
            var metrics = usage[1]["metrics"] as! [[String: Any]]
            metrics[0]["amounts"] = ["remaining":42, "limit":100, "unit":"credits"]
            metrics[0]["consumption"] = ["used":70, "unit":"credits"]
            usage[1]["metrics"] = metrics; root["usage"] = usage
        }
        let host = try QuotioHostSnapshot.decode(Data(fixture.utf8))
        let snapshot = QuotioHostPresentationMapper.resolvedSnapshot(host)
        XCTAssertEqual(snapshot.quotas[.devin]?["devin-desktop-account"]?.models.first?.presentation,
            .progress(used: 70, limit: 100, unit: .credits))
    }

    func testLogicalRedirectsNeverFollowAReassignedSourceID() throws {
        let fixture = try hostFixture { root in
            var accounts = root["accounts"] as! [[String: Any]]
            accounts[0]["id"] = "old-account"
            var oldSources = accounts[0]["sources"] as! [[String: Any]]
            oldSources[0]["id"] = "remaining-source"; accounts[0]["sources"] = oldSources
            accounts[1]["id"] = "new-account"; accounts[1]["provider_id"] = "copilot"
            var newSources = accounts[1]["sources"] as! [[String: Any]]
            newSources[0]["id"] = "old-account"; accounts[1]["sources"] = newSources
            root["accounts"] = accounts
            var usage = root["usage"] as! [[String: Any]]
            usage[0]["account_id"] = "old-account"; usage[1]["account_id"] = "new-account"
            root["usage"] = usage
            root["account_redirects"] = ["old-alias":"old-account"]
        }
        let host = try QuotioHostSnapshot.decode(Data(fixture.utf8))
        let snapshot = QuotioHostPresentationMapper.resolvedSnapshot(host)
        XCTAssertEqual(snapshot.accountAliases[.copilot]?["old-account"], "old-account")
        XCTAssertEqual(snapshot.accountAliases[.copilot]?["old-alias"], "old-account")
        XCTAssertEqual(snapshot.accountAliases[.copilot]?["new-account"], "new-account")
    }

    func testKnownZeroAnalyticsAreNotTurnedIntoMissingData() throws {
        let fixture = try hostFixture { root in
            var accounts = root["accounts"] as! [[String: Any]]
            accounts[0]["provider_id"] = "codex"; root["accounts"] = accounts
            var usage = root["usage"] as! [[String: Any]]
            usage[0]["codex_profile"] = ["daily_usage":[], "latest_30_buckets_tokens":0,
                "lifetime_tokens":0, "fetched_at":"2026-09-24T12:00:00Z"]
            root["usage"] = usage
        }
        let host = try QuotioHostSnapshot.decode(Data(fixture.utf8))
        let snapshot = QuotioHostPresentationMapper.resolvedSnapshot(host)
        let rows = try XCTUnwrap(snapshot.quotas[.codex]?["copilot-account"]?.analytics?.rows)
        XCTAssertEqual(rows.first { $0.id == "last-30-days" }?.value, "0 tokens")
        XCTAssertEqual(rows.first { $0.id == "codex-lifetime-tokens" }?.value, "0 tokens")
        XCTAssertNil(rows.first { $0.id == "codex-peak-daily" })
        XCTAssertEqual(rows.first { $0.id == "today" }?.isAvailable, false)
    }

    private func stubSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [QuotioCLIURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

@MainActor
private struct QuotioCLIURLOpenerStub: URLOpening {
    func open(_ url: URL) -> Bool { true }
}

private final class QuotioCLIURLProtocol: URLProtocol, @unchecked Sendable {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var bodies: [(Data, Int)] = []
    nonisolated(unsafe) private static var recordedRequests: [URLRequest] = []
    nonisolated(unsafe) private static var recordedBodies: [Data?] = []

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let requestBody = Self.readBody(from: request)
        let (body, status) = Self.lock.withLock { () -> (Data, Int) in
            Self.recordedRequests.append(request)
            Self.recordedBodies.append(requestBody)
            return Self.bodies.removeFirst()
        }
        let response = HTTPURLResponse(
            url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    static func enqueue(_ body: String, status: Int = 200) {
        lock.withLock { bodies.append((Data(body.utf8), status)) }
    }

    static func requests() -> [URLRequest] {
        lock.withLock { recordedRequests }
    }

    static func body(forPath path: String) -> Data? {
        lock.withLock {
            zip(recordedRequests, recordedBodies).first { $0.0.url?.path == path }?.1
        }
    }

    static func bodies(forPath path: String) -> [Data] {
        lock.withLock {
            zip(recordedRequests, recordedBodies).compactMap {
                $0.0.url?.path == path ? $0.1 : nil
            }
        }
    }

    static func reset() {
        lock.withLock {
            bodies = []
            recordedRequests = []
            recordedBodies = []
        }
    }

    private static func readBody(from request: URLRequest) -> Data? {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)
        while true {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { return data }
            data.append(buffer, count: count)
        }
    }
}
