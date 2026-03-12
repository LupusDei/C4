import ComposableArchitecture
import CoreKit
import Foundation

@Reducer
public struct CreditReducer: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        public var balance: Int = 0
        public var transactions: [CreditTransaction] = []
        public var isLoadingBalance: Bool = false
        public var isLoadingHistory: Bool = false
        public var error: String?
        public var showAllocateSheet: Bool = false
        public var allocateAmount: String = ""

        public init() {}

        public var isLoading: Bool {
            isLoadingBalance || isLoadingHistory
        }

        public var parsedAllocateAmount: Int? {
            Int(allocateAmount.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        public var canAllocate: Bool {
            guard let amount = parsedAllocateAmount else { return false }
            return amount > 0
        }
    }

    public enum Action: Sendable {
        case onAppear
        case loadBalance
        case loadHistory
        case balanceLoaded(Result<BalanceResponse, Error>)
        case historyLoaded(Result<[CreditTransaction], Error>)
        case allocateTapped
        case dismissAllocateSheet
        case setAllocateAmount(String)
        case submitAllocate
        case allocateResponse(Result<CreditAccount, Error>)
        case refresh
    }

    @Dependency(\.apiClient) var apiClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.balance == 0 && state.transactions.isEmpty else { return .none }
                return .merge(
                    .send(.loadBalance),
                    .send(.loadHistory)
                )

            case .loadBalance:
                state.isLoadingBalance = true
                state.error = nil
                return .run { send in
                    let result = await Result {
                        try await apiClient.get("/api/credits/balance", as: BalanceResponse.self)
                    }
                    await send(.balanceLoaded(result))
                }

            case .loadHistory:
                state.isLoadingHistory = true
                state.error = nil
                return .run { send in
                    let result = await Result {
                        try await apiClient.get(
                            "/api/credits/history?limit=50",
                            as: [CreditTransaction].self
                        )
                    }
                    await send(.historyLoaded(result))
                }

            case .balanceLoaded(.success(let response)):
                state.isLoadingBalance = false
                state.balance = response.balance
                return .none

            case .balanceLoaded(.failure(let error)):
                state.isLoadingBalance = false
                state.error = error.localizedDescription
                return .none

            case .historyLoaded(.success(let transactions)):
                state.isLoadingHistory = false
                state.transactions = transactions
                return .none

            case .historyLoaded(.failure(let error)):
                state.isLoadingHistory = false
                state.error = error.localizedDescription
                return .none

            case .allocateTapped:
                state.showAllocateSheet = true
                state.allocateAmount = ""
                return .none

            case .dismissAllocateSheet:
                state.showAllocateSheet = false
                return .none

            case .setAllocateAmount(let amount):
                state.allocateAmount = amount
                return .none

            case .submitAllocate:
                guard let amount = state.parsedAllocateAmount, amount > 0 else { return .none }
                state.showAllocateSheet = false

                let request = AllocateRequest(amount: amount)

                return .run { send in
                    let result = await Result {
                        try await apiClient.post(
                            "/api/credits/allocate",
                            body: request,
                            as: CreditAccount.self
                        )
                    }
                    await send(.allocateResponse(result))
                }

            case .allocateResponse(.success(let account)):
                state.balance = account.balance
                state.transactions = account.transactions
                return .none

            case .allocateResponse(.failure(let error)):
                state.error = error.localizedDescription
                return .none

            case .refresh:
                return .merge(
                    .send(.loadBalance),
                    .send(.loadHistory)
                )
            }
        }
    }
}

// MARK: - API Types

public struct BalanceResponse: Codable, Sendable {
    public let balance: Int
}

struct AllocateRequest: Codable, Sendable {
    let amount: Int
}
