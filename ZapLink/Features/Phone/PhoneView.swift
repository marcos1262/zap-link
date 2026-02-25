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
                        Text("Enter the phone number:")
                            .font(.title2)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack {
                            TextField("Type a phone number", text: $store.phoneNumber)
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.phonePad)

                            Button(action: {
                                store.send(.pasteButtonTapped)
                            }) {
                                Label("Paste", systemImage: "doc.on.clipboard")
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
                            }
                            .disabled(!store.isPasteEnabled)
                        }

                        if let validationMessage = store.validationMessage {
                            Text(validationMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    Button("Open") {
                        store.send(.openButtonTapped)
                    }
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color("AccentColor"))
                    )
                    .opacity(store.isOpenEnabled ? 1 : 0.6)
                    .disabled(!store.isOpenEnabled)
                }
                .padding()
            }
            .navigationTitle("Zap Link")
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
