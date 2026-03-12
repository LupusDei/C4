import ComposableArchitecture
import CoreKit
import SwiftUI

public struct CreditView: View {
    @Bindable var store: StoreOf<CreditReducer>

    public init(store: StoreOf<CreditReducer>) {
        self.store = store
    }

    public var body: some View {
        Group {
            if store.isLoading && store.transactions.isEmpty {
                ProgressView("Loading credits...")
            } else if let error = store.error, store.transactions.isEmpty {
                errorState(error)
            } else {
                contentView
            }
        }
        .navigationTitle("Credits")
        .onAppear { store.send(.onAppear) }
        .sheet(isPresented: Binding(
            get: { store.showAllocateSheet },
            set: { if !$0 { store.send(.dismissAllocateSheet) } }
        )) {
            allocateSheet
        }
    }

    // MARK: - Content

    private var contentView: some View {
        List {
            Section {
                balanceHeader
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            if let error = store.error {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Transaction History") {
                if store.transactions.isEmpty {
                    ContentUnavailableView {
                        Label("No Transactions", systemImage: "clock")
                    } description: {
                        Text("Your credit history will appear here.")
                    }
                } else {
                    ForEach(store.transactions) { transaction in
                        transactionRow(transaction)
                    }
                }
            }
        }
        .refreshable {
            store.send(.refresh)
        }
    }

    // MARK: - Balance Header

    private var balanceHeader: some View {
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                Text("\(store.balance)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))

                Text("credits")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)

            Button {
                store.send(.allocateTapped)
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Credits")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Transaction Row

    private func transactionRow(_ transaction: CreditTransaction) -> some View {
        HStack(spacing: 12) {
            transactionIcon(transaction.type)

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description)
                    .font(.body)
                    .lineLimit(1)

                Text(transaction.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Text(transactionAmountText(transaction))
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
                .foregroundStyle(transactionColor(transaction.type))
        }
        .padding(.vertical, 4)
        .overlay(alignment: .bottom) {
            // Hairline separator (#E7E5E4)
            Rectangle()
                .fill(Color(red: 231/255, green: 229/255, blue: 228/255))
                .frame(height: 0.5)
        }
    }

    private func transactionIcon(_ type: CreditTransactionType) -> some View {
        Image(systemName: transactionIconName(type))
            .font(.title3)
            .foregroundStyle(transactionColor(type))
            .frame(width: 28)
    }

    private func transactionIconName(_ type: CreditTransactionType) -> String {
        switch type {
        case .debit: "arrow.down.circle"
        case .credit: "arrow.up.circle"
        case .refund: "arrow.counterclockwise"
        }
    }

    private func transactionColor(_ type: CreditTransactionType) -> Color {
        switch type {
        case .debit: Color(red: 120/255, green: 113/255, blue: 108/255) // warm gray #78716C
        case .credit: Color(red: 101/255, green: 163/255, blue: 13/255) // sage green #65A30D
        case .refund: Color(red: 101/255, green: 163/255, blue: 13/255) // sage green #65A30D
        }
    }

    private func transactionAmountText(_ transaction: CreditTransaction) -> String {
        switch transaction.type {
        case .debit: "-\(transaction.amount)"
        case .credit: "+\(transaction.amount)"
        case .refund: "+\(transaction.amount)"
        }
    }

    // MARK: - Error State

    private func errorState(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Error", systemImage: "exclamationmark.triangle.fill")
        } description: {
            Text(message)
        } actions: {
            Button("Retry") {
                store.send(.refresh)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Allocate Sheet

    private var allocateSheet: some View {
        NavigationStack {
            Form {
                Section("Quick Add") {
                    HStack(spacing: 12) {
                        ForEach([100, 500, 1000], id: \.self) { amount in
                            Button {
                                store.send(.setAllocateAmount("\(amount)"))
                            } label: {
                                Text("\(amount)")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        store.allocateAmount == "\(amount)"
                                            ? Color.accentColor
                                            : Color(.systemGray5)
                                    )
                                    .foregroundStyle(
                                        store.allocateAmount == "\(amount)"
                                            ? .white
                                            : .primary
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                Section("Custom Amount") {
                    TextField("Enter amount", text: Binding(
                        get: { store.allocateAmount },
                        set: { store.send(.setAllocateAmount($0)) }
                    ))
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif
                }
            }
            .navigationTitle("Add Credits")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { store.send(.dismissAllocateSheet) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { store.send(.submitAllocate) }
                        .disabled(!store.canAllocate)
                }
            }
        }
    }
}
