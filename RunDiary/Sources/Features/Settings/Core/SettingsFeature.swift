//
//  SettingsFeature.swift
//  RunDiary
//
//  Created by Claude on 12/15/25.
//

import ComposableArchitecture
import Foundation
import LegacyMigration

@Reducer
struct SettingsFeature {
    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var isPreparingMigration = false
        var isMigrating = false
        var migrationPreparation: MigrationPreparation?
        var migrationProgress = MigrationProgress()
        var migrationMessage: String?
    }

    // MARK: - Action

    enum Action {
        case settingsItemTapped(SettingsItem)
        case migrationTapped
        case migrationPrepared(MigrationPreparation)
        case migrationConfirmed
        case migrationDismissed
        case migrationProgressed(MigrationProgress)
        case migrationFinished(MigrationProgress)
        case migrationFailed(String)
        case migrationCancelled
    }

    // MARK: - SettingsItem

    enum SettingsItem: String, CaseIterable, Identifiable {
        case privacyPolicy
        case termsOfService

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .privacyPolicy: return L10n.settingsPrivacyPolicy.value
            case .termsOfService: return L10n.settingsTermsOfService.value
            }
        }

        var url: String {
            let languageCode = Locale.current.language.languageCode?.identifier ?? "ko"
            let supportedLanguage: String

            // 지원 언어: ko, en, ja (기본값: ko)
            switch languageCode {
            case "en": supportedLanguage = "en"
            case "ja": supportedLanguage = "ja"
            default: supportedLanguage = "ko"
            }

            switch self {
            case .privacyPolicy:
                return "https://apps.kimhyeji.dev/run-diary/privacy-policy/\(supportedLanguage)/"
            case .termsOfService:
                return "https://apps.kimhyeji.dev/run-diary/use-of-terms/\(supportedLanguage)/"
            }
        }
    }

    // MARK: - Reducer

    @Dependency(\.legacyMigrationClient) var legacyMigrationClient
    private nonisolated enum CancelID: Hashable, Sendable { case migration }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .migrationTapped:
                guard !state.isMigrating, !state.isPreparingMigration else { return .none }
                state.isPreparingMigration = true
                state.migrationMessage = nil
                return .run { send in
                    do {
                        await send(.migrationPrepared(try await legacyMigrationClient.prepare()))
                    } catch is CancellationError {
                    } catch {
                        await send(.migrationFailed(error.localizedDescription))
                    }
                }.cancellable(id: CancelID.migration)

            case .migrationPrepared(let preparation):
                state.isPreparingMigration = false
                state.migrationPreparation = preparation
                return .none

            case .migrationConfirmed:
                guard let preparation = state.migrationPreparation, !state.isMigrating else { return .none }
                state.migrationPreparation = nil
                state.isMigrating = true
                state.migrationProgress = MigrationProgress(total: preparation.count)
                return .run { send in
                    do {
                        let result = try await legacyMigrationClient.run { progress in
                            await send(.migrationProgressed(progress))
                        }
                        await send(.migrationFinished(result))
                    } catch is CancellationError {
                    } catch {
                        await send(.migrationFailed(error.localizedDescription))
                    }
                }.cancellable(id: CancelID.migration)

            case .migrationDismissed:
                state.migrationPreparation = nil
                return .none

            case .migrationProgressed(let progress):
                state.migrationProgress = progress
                return .none

            case .migrationFinished(let progress):
                state.isMigrating = false
                state.migrationProgress = progress
                state.migrationMessage =
                    progress.failures == 0
                    ? "기록 \(progress.completed)개를 서버에서 확인했어요. 기기의 원본은 유지돼요."
                    : "완료 \(progress.completed)개, 확인 필요 \(progress.failures)개. \(progress.message ?? "")"
                return .none

            case .migrationFailed(let message):
                state.isPreparingMigration = false
                state.isMigrating = false
                state.migrationMessage = message
                return .none

            case .migrationCancelled:
                state.isPreparingMigration = false
                state.isMigrating = false
                state.migrationPreparation = nil
                state.migrationMessage = "전송을 중단했어요. 다시 시작하면 완료한 기록은 건너뛰어요."
                return .cancel(id: CancelID.migration)

            case .settingsItemTapped(let item):
                AppLogger.settings.debug("settingsItemTapped - item: \(item.displayName)")
                return .run { _ in
                    await MainActor.run {
                        URLOpener.open(url: item.url)
                    }
                }
            }
        }
    }
}
