//
//  SettingsView.swift
//  RunDiary
//
//  Created by Claude on 12/15/25.
//

import ComposableArchitecture
import LegacyMigration
import SwiftUI

struct SettingsView: View {
    let store: StoreOf<SettingsFeature>

    var body: some View {
        List {
            Section("기존 기록 전송") {
                Text("이 기기에 저장된 기록을 로그인한 계정으로 보내요. 원본은 그대로 유지되며, 이후 수정·삭제는 자동으로 동기화되지 않아요.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button(store.isPreparingMigration ? "기록 확인 중…" : "기존 기록 서버로 보내기") {
                    store.send(.migrationTapped)
                }
                .disabled(store.isPreparingMigration || store.isMigrating)
                if store.isMigrating {
                    ProgressView(
                        value: Double(store.migrationProgress.completed),
                        total: Double(max(1, store.migrationProgress.total))
                    )
                    Text("\(store.migrationProgress.completed) / \(store.migrationProgress.total)개 확인 완료")
                    Button("전송 중단", role: .cancel) { store.send(.migrationCancelled) }
                }
                if let message = store.migrationMessage {
                    Text(message).font(.footnote)
                }
            }
            Section {
                ForEach(SettingsFeature.SettingsItem.allCases) { item in
                    Button {
                        store.send(.settingsItemTapped(item))
                    } label: {
                        HStack {
                            Text(item.displayName)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "기존 기록을 이 계정으로 보낼까요?",
            isPresented: Binding(
                get: { store.migrationPreparation != nil },
                set: { if !$0 { store.send(.migrationDismissed) } }
            ),
            titleVisibility: .visible
        ) {
            Button("기록 보내기") { store.send(.migrationConfirmed) }
            Button("취소", role: .cancel) { store.send(.migrationDismissed) }
        } message: {
            if let preparation = store.migrationPreparation {
                Text("\(preparation.accountLabel) 계정으로 기록 \(preparation.count)개를 보내요. 이미 보낸 기록은 중복 저장하지 않아요.")
            }
        }
        .onDisappear {
            if store.isMigrating || store.isPreparingMigration { store.send(.migrationCancelled) }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView(
            store: Store(initialState: SettingsFeature.State()) {
                SettingsFeature()
            } withDependencies: {
                $0.legacyMigrationClient = .previewValue
            })
    }
}
