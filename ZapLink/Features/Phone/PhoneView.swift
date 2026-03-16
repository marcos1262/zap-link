import ComposableArchitecture
import SwiftUI

struct PhoneView: View {

    @Environment(\.scenePhase) private var scenePhase

    @Perception.Bindable private var store: StoreOf<PhoneFeature>

    init(store: StoreOf<PhoneFeature>) {
        self.store = store
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Image("background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .colorMultiply(.secondary)
                    .opacity(0.3)

                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        Text(String(localized: "Digite o número de telefone:"))
                            .font(.title2)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack {
                            TextField(String(localized: "Digite um número de telefone"), text: $store.phoneNumber)
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.phonePad)

                            Button(action: {
                                store.send(.pasteButtonTapped)
                            }) {
                                Label(String(localized: "Colar"), systemImage: "doc.on.clipboard")
                                    .foregroundColor(store.isPasteEnabled ?
                                                     Color("AccentColor") :
                                                        Color("AccentColor").opacity(0.5))
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(store.isPasteEnabled ?
                                                    Color("AccentColor") :
                                                        Color("AccentColor").opacity(0.5),
                                                    lineWidth: 1)
                                    )
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.background)
                                    )
                                    .contentShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .disabled(!store.isPasteEnabled)
                        }

                        if store.isClipboardImportPromptVisible {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "doc.on.clipboard")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 2)

                                VStack(alignment: .leading, spacing: 8) {
                                    Text(String(localized: "Número encontrado na área de transferência"))
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)

                                    HStack(spacing: 10) {
                                        Button(String(localized: "Importar")) {
                                            store.send(.clipboardImportPromptTapped)
                                        }
                                        .font(.footnote.weight(.semibold))
                                        .buttonStyle(.borderedProminent)
                                        .controlSize(.regular)

                                        Button(String(localized: "Agora não")) {
                                            store.send(.clipboardImportPromptDismissed)
                                        }
                                        .font(.footnote)
                                        .buttonStyle(.bordered)
                                        .controlSize(.regular)
                                        .tint(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color("AccentColor").opacity(0.08))
                            )
                        }

                        if store.shouldShowValidationError {
                            Text(String(localized: "Digite um número de telefone válido"))
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    Button {
                        store.send(.openButtonTapped)
                    } label: {
                        Text(String(localized: "Abrir"))
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color("AccentColor"))
                            )
                            .contentShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .opacity(store.isOpenEnabled ? 1 : 0.6)
                    .disabled(!store.isOpenEnabled)
                }
                .padding()
            }
            .navigationTitle(String(localized: "Zap Link"))
        }
        .onAppear {
            store.send(.scenePhaseUpdated)
        }
        .onChange(of: scenePhase) { _ in
            store.send(.scenePhaseUpdated)
        }
    }
}

#Preview {
    PhoneView(store: Store(initialState: PhoneFeature.State()) {
        PhoneFeature()
    })
}
