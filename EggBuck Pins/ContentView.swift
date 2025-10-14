

// Colors.swift
import SwiftUI

extension Color {
    static let eggYellow = Color(hex: "#FFD93D")
    static let coralRed = Color(hex: "#FF6B6B")
    static let skyBlue = Color(hex: "#4A90E2")
    static let grassGreen = Color(hex: "#3DD598")
    static let creamyWhite = Color(hex: "#FFF9E6")
    
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >>  8) & 0xFF) / 255.0
        let b = Double((rgb >>  0) & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

// Custom Modifiers
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                LinearGradient(gradient: Gradient(colors: [.white, .creamyWhite.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .gray.opacity(0.2), radius: 10, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.gray.opacity(0.1), lineWidth: 1)
            )
    }
}

struct ButtonStyleCustom: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded, weight: .bold))
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(gradient: Gradient(colors: [.skyBlue, .grassGreen]), startPoint: .leading, endPoint: .trailing)
            )
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct PlaceholderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(.gray.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .gray.opacity(0.1), radius: 5)
    }
}

// Models
import Foundation

enum ExpenseCategory: String, CaseIterable, Codable {
    case feed = "Feed"
    case electricity = "Electricity"
    case medicine = "Medicine"
    case repair = "Repair"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .feed: return "leaf.fill"
        case .electricity: return "bolt.fill"
        case .medicine: return "pills.fill"
        case .repair: return "hammer.fill"
        case .other: return "gearshape.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .feed: return .grassGreen
        case .electricity: return .skyBlue
        case .medicine: return .coralRed
        case .repair: return .eggYellow
        case .other: return .gray
        }
    }
}

struct Expense: Identifiable, Codable {
    var id = UUID()
    var amount: Double
    var category: ExpenseCategory
    var date: Date
    var note: String?
}

struct EggBatch: Identifiable, Codable, Equatable {
    var id = UUID()
    var quantity: Int
    var collectionDate: Date
    var expiryDate: Date
    
    var status: EggStatus {
        let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
        if daysLeft > 7 { return .fresh }
        else if daysLeft > 0 { return .expiringSoon }
        else { return .expired }
    }
    
    var emoji: String {
        switch status {
        case .fresh: return "🥚😊"
        case .expiringSoon: return "🥚😅"
        case .expired: return "🥚😢"
        }
    }
    
    var color: Color {
        switch status {
        case .fresh: return .grassGreen
        case .expiringSoon: return .eggYellow
        case .expired: return .coralRed
        }
    }
    
    static func ==(lhs: EggBatch, rhs: EggBatch) -> Bool {
        return lhs.id == rhs.id
    }
}

enum EggStatus {
    case fresh, expiringSoon, expired
}

// ViewModel
class AppViewModel: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var eggBatches: [EggBatch] = []
    
    init() {
        loadData()
        scheduleExpiryNotifications()
    }
    
    func addExpense(_ expense: Expense) {
        expenses.append(expense)
        saveData()
    }
    
    func updateExpense(_ expense: Expense) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = expense
            saveData()
        }
    }
    
    func deleteExpense(_ expense: Expense) {
        expenses.removeAll { $0.id == expense.id }
        saveData()
    }
    
    func addEggBatch(_ batch: EggBatch) {
        eggBatches.append(batch)
        saveData()
        scheduleExpiryNotifications()
    }
    
    func updateEggBatch(_ batch: EggBatch) {
        if let index = eggBatches.firstIndex(where: { $0.id == batch.id }) {
            eggBatches[index] = batch
            saveData()
            scheduleExpiryNotifications()
        }
    }
    
    func deleteEggBatch(_ batch: EggBatch) {
        eggBatches.removeAll { $0.id == batch.id }
        saveData()
        scheduleExpiryNotifications()
    }
    
    private func saveData() {
        if let encodedExpenses = try? JSONEncoder().encode(expenses) {
            UserDefaults.standard.set(encodedExpenses, forKey: "expenses")
        }
        if let encodedEggs = try? JSONEncoder().encode(eggBatches) {
            UserDefaults.standard.set(encodedEggs, forKey: "eggBatches")
        }
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: "expenses"),
           let decoded = try? JSONDecoder().decode([Expense].self, from: data) {
            expenses = decoded
        }
        if let data = UserDefaults.standard.data(forKey: "eggBatches"),
           let decoded = try? JSONDecoder().decode([EggBatch].self, from: data) {
            eggBatches = decoded
        }
    }
    
    var todayExpenses: Double {
        let today = Calendar.current.startOfDay(for: Date())
        return expenses.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }.reduce(0) { $0 + $1.amount }
    }
    
    var totalEggsInBasket: Int {
        eggBatches.reduce(0) { $0 + $1.quantity }
    }
    
    var freshEggs: Int {
        eggBatches.filter { $0.status == .fresh }.reduce(0) { $0 + $1.quantity }
    }
    
    var eggsCollectedThisWeek: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return eggBatches.filter { $0.collectionDate >= weekAgo }.reduce(0) { $0 + $1.quantity }
    }
    
    var eggsCollectedThisMonth: Int {
        let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        return eggBatches.filter { $0.collectionDate >= monthAgo }.reduce(0) { $0 + $1.quantity }
    }
    
    var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    var averageCostPerEgg: Double {
        totalEggsInBasket > 0 ? totalExpenses / Double(totalEggsInBasket) : 0
    }
    
    var badges: [Badge] {
        [
            Badge(name: "Golden Dozen", achieved: totalEggsInBasket >= 12, icon: "trophy.fill"),
            Badge(name: "100 Eggs", achieved: totalEggsInBasket >= 100, icon: "rosette"),
            Badge(name: "Thrifty Farmer", achieved: averageCostPerEgg < 5, icon: "dollarsign.circle.fill"),
            Badge(name: "Egg Master", achieved: eggsCollectedThisMonth >= 500, icon: "crown.fill"),
            Badge(name: "Zero Waste", achieved: eggBatches.allSatisfy { $0.status != .expired }, icon: "leaf.circle.fill")
        ]
    }
    
    struct Badge {
        let name: String
        let achieved: Bool
        let icon: String
    }
    
    var expenseByCategory: [String: Double] {
        Dictionary(grouping: expenses, by: { $0.category.rawValue })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
    }
    
    var dailyExpenses: [(date: Date, amount: Double)] {
        let grouped = Dictionary(grouping: expenses, by: { Calendar.current.startOfDay(for: $0.date) })
        return grouped.map { (date: $0.key, amount: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.date < $1.date }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    func scheduleExpiryNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        for batch in eggBatches {
            if batch.status == .expiringSoon {
                let content = UNMutableNotificationContent()
                content.title = "Cluck Cluck! Eggs Expiring Soon"
                content.body = "\(batch.quantity) eggs collected on \(dateFormatter.string(from: batch.collectionDate)) are expiring on \(dateFormatter.string(from: batch.expiryDate))."
                content.sound = UNNotificationSound.default
                content.badge = NSNumber(integerLiteral: freshEggs)
                
                let triggerDate = Calendar.current.date(byAdding: .day, value: -1, to: batch.expiryDate) ?? Date()
                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                
                let request = UNNotificationRequest(identifier: batch.id.uuidString, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
            }
        }
        
        let averageDaily = totalExpenses / Double(max(1, dailyExpenses.count))
        if todayExpenses > averageDaily * 1.5 {
            let content = UNMutableNotificationContent()
            content.title = "Cluck Alert! High Expenses Today"
            content.body = "Today's expenses are higher than usual. Check your spending!"
            content.sound = UNNotificationSound.default
            content.badge = NSNumber(integerLiteral: 1)
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
            let request = UNNotificationRequest(identifier: "highExpense", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }
}

// ContentView.swift
struct ContentView: View {
    @StateObject var viewModel = AppViewModel()
    @State private var urlFromNotification: String? = nil
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            ExpensesView()
                .tabItem { Label("Expenses", systemImage: "dollarsign.circle.fill") }
            EggsView()
                .tabItem { Label("Eggs", systemImage: "oval.fill") }
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
        }
        .environmentObject(viewModel)
        .accentColor(.eggYellow)
        .font(.system(.body, design: .rounded))
        .onAppear {
            viewModel.scheduleExpiryNotifications()
            UIApplication.shared.applicationIconBadgeNumber = viewModel.freshEggs
        }
        .fullScreenCover(isPresented: Binding<Bool>(
            get: { urlFromNotification != nil },
            set: { newValue in if !newValue { urlFromNotification = nil } }
        )) {
            if let urlToOpen = urlFromNotification {
                Detail(urlString: urlToOpen)
            } else {
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openUrlFromNotification)) { notification in
            if let userInfo = notification.userInfo,
               let url = userInfo["url"] as? String {
                urlFromNotification = url
            }
        }
    }
}

// DashboardView.swift
struct DashboardView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showingAddSheet = false
    @State private var selectedAddType: AddType? = nil
    @State private var scale = 1.0
    
    enum AddType: Identifiable, Hashable {
        case expense, egg
        var id: Self { self }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [.creamyWhite, .white.opacity(0.9)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    header
                    cards
                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                        withAnimation(.spring()) {
                            scale = 1.2
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.spring()) {
                                scale = 1.0
                            }
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .foregroundStyle(.linearGradient(colors: [.grassGreen, .skyBlue], startPoint: .top, endPoint: .bottom))
                            .scaleEffect(scale)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddSelectionSheet(selectedAddType: $selectedAddType, showing: $showingAddSheet)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedAddType) { type in
                switch type {
                case .expense:
                    AddExpenseView()
                case .egg:
                    AddEggView()
                }
            }
        }
    }
    
    var header: some View {
        HStack {
            Text("Hello, Farmer! 🐔")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.linearGradient(colors: [.coralRed, .eggYellow], startPoint: .leading, endPoint: .trailing))
            Spacer()
            Image(systemName: "bird.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundStyle(.linearGradient(colors: [.eggYellow, .coralRed], startPoint: .top, endPoint: .bottom))
                .shadow(color: .gray.opacity(0.4), radius: 4)
                .rotationEffect(.degrees(10))
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: scale)
                .onAppear { scale = 1.1 }
                .scaleEffect(scale)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    var cards: some View {
        VStack(spacing: 16) {
            CardView(title: "Today's Expenses", value: String(format: "$%.2f", viewModel.todayExpenses), icon: "bag.fill")
                .transition(.scale.combined(with: .opacity))
            CardView(title: "Eggs in Basket", value: "\(viewModel.totalEggsInBasket) (\(viewModel.freshEggs) fresh)", icon: "basket.fill")
                .transition(.scale.combined(with: .opacity))
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.todayExpenses)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.totalEggsInBasket)
    }
}

// CardView
struct CardView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .foregroundStyle(.linearGradient(colors: [.skyBlue, .grassGreen], startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: .gray.opacity(0.3), radius: 3)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundColor(.gray.opacity(0.8))
                Text(value)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.linearGradient(colors: [.coralRed, .eggYellow], startPoint: .leading, endPoint: .trailing))
            }
            Spacer()
        }
        .modifier(CardStyle())
        .padding(.horizontal)
    }
}

// AddSelectionSheet
struct AddSelectionSheet: View {
    @Binding var selectedAddType: DashboardView.AddType?
    @Binding var showing: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Add New")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(.linearGradient(colors: [.skyBlue, .grassGreen], startPoint: .leading, endPoint: .trailing))
            
            Button("Expense") {
                selectedAddType = .expense
                showing = false
            }
            .buttonStyle(ButtonStyleCustom())
            
            Button("Egg Batch") {
                selectedAddType = .egg
                showing = false
            }
            .buttonStyle(ButtonStyleCustom())
        }
        .padding()
        .background(Color.creamyWhite)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(radius: 10)
        .padding(.horizontal)
    }
}

// ExpensesView.swift (added placeholder)
struct ExpensesView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showingAdd = false
    @State private var editingExpense: Expense?
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [.creamyWhite, .white.opacity(0.9)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                if viewModel.expenses.isEmpty && viewModel.expenseByCategory.isEmpty {
                    placeholderView
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            charts
                            expenseList
                        }
                        .padding(.bottom)
                    }
                }
            }
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.grassGreen)
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddExpenseView()
            }
            .sheet(item: $editingExpense) { expense in
                AddExpenseView(expense: expense)
            }
            .refreshable {
                viewModel.scheduleExpiryNotifications()
            }
        }
    }
    
    var placeholderView: some View {
        VStack(spacing: 16) {
            Image(systemName: "dollarsign.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(.linearGradient(colors: [.gray.opacity(0.5), .gray], startPoint: .top, endPoint: .bottom))
            
            Text("No Expenses Yet")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundColor(.gray)
            
            Text("Tap the '+' button to add your first expense!")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button("Add Expense") {
                showingAdd = true
            }
            .buttonStyle(ButtonStyleCustom())
            .padding(.horizontal, 40)
        }
        .modifier(PlaceholderStyle())
        .padding(.horizontal)
    }
    
    var charts: some View {
        VStack(spacing: 16) {
            PieChartView(data: viewModel.expenseByCategory)
                .frame(height: 240)
                .modifier(CardStyle())
            
            LineChartView(data: viewModel.dailyExpenses)
                .frame(height: 240)
                .modifier(CardStyle())
        }
        .padding(.horizontal)
    }
    
    var expenseList: some View {
        List {
            ForEach(viewModel.expenses.sorted(by: { $0.date > $1.date })) { expense in
                ExpenseCard(expense: expense)
                    .onTapGesture {
                        editingExpense = expense
                    }
            }
            .onDelete { indices in
                indices.forEach { viewModel.deleteExpense(viewModel.expenses.sorted(by: { $0.date > $1.date })[$0]) }
            }
        }
        .listStyle(.plain)
        .background(Color.clear)
    }
}

// ExpenseCard
struct ExpenseCard: View {
    let expense: Expense
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: expense.category.icon)
                .font(.title2)
                .foregroundStyle(.linearGradient(colors: [expense.category.color, expense.category.color.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.category.rawValue)
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.coralRed)
                if let note = expense.note, !note.isEmpty {
                    Text(note)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.gray.opacity(0.8))
                        .lineLimit(2)
                }
                Text(expense.date, format: .dateTime.year().month().day())
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.gray.opacity(0.7))
            }
            Spacer()
            Text(String(format: "$%.2f", expense.amount))
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(.linearGradient(colors: [.grassGreen, .skyBlue], startPoint: .leading, endPoint: .trailing))
        }
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.horizontal, 8)
    }
}

// AddExpenseView
struct AddExpenseView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    
    @State var expense: Expense
    @State private var note: String
    
    init(expense: Expense? = nil) {
        if let expense = expense {
            _expense = State(initialValue: expense)
            _note = State(initialValue: expense.note ?? "")
        } else {
            _expense = State(initialValue: Expense(amount: 0, category: .feed, date: Date(), note: ""))
            _note = State(initialValue: "")
        }
    }
    
    var isEdit: Bool { expense.amount != 0 && expense.category != .feed && expense.note != "" }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Amount")) {
                    TextField("Amount", value: $expense.amount, format: .number)
                        .keyboardType(.decimalPad)
                        .font(.system(.body, design: .rounded))
                }
                
                Section(header: Text("Category")) {
                    Picker("Category", selection: $expense.category) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                            HStack {
                                Image(systemName: cat.icon)
                                    .foregroundStyle(cat.color)
                                Text(cat.rawValue)
                            }
                            .tag(cat)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                
                Section(header: Text("Date")) {
                    DatePicker("Date", selection: $expense.date, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                }
                
                Section(header: Text("Note")) {
                    TextField("Note (optional)", text: $note, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
            }
            .navigationTitle(isEdit ? "Edit Expense" : "Add Expense")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        expense.note = note.isEmpty ? nil : note
                        if isEdit {
                            viewModel.updateExpense(expense)
                        } else {
                            viewModel.addExpense(expense)
                        }
                        dismiss()
                    }
                    .disabled(expense.amount <= 0)
                    .font(.system(.headline, design: .rounded))
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.system(.headline, design: .rounded))
                }
                if isEdit {
                    ToolbarItem(placement: .bottomBar) {
                        Button("Delete", role: .destructive) {
                            viewModel.deleteExpense(expense)
                            dismiss()
                        }
                        .font(.system(.headline, design: .rounded))
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// PieChartView
struct PieChartView: View {
    let data: [String: Double]
    private var total: Double { data.values.reduce(0, +) }
    private let colors: [Color] = [.grassGreen, .skyBlue, .coralRed, .eggYellow, .purple]
    
    var slices: [(category: String, value: Double, color: Color)] {
        Array(data.sorted(by: { $0.key < $1.key }).enumerated().map { index, element in
            (element.key, element.value, colors[index % colors.count])
        })
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Category Breakdown")
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.gray.opacity(0.8))
            
            if data.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.pie.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundStyle(.gray.opacity(0.5))
                    Text("No Data Available")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.gray.opacity(0.7))
                }
                .frame(height: 200)
            } else {
                GeometryReader { geo in
                    ZStack {
                        var startAngle: Angle = .zero
                        ForEach(slices, id: \.category) { slice in
                            let angle = Angle(degrees: (slice.value / total) * 360)
                            PieSlice(startAngle: startAngle, endAngle: startAngle + angle)
                                .fill(slice.color)
                                .overlay(
                                    PieSlice(startAngle: startAngle, endAngle: startAngle + angle)
                                        .stroke(.white, lineWidth: 1)
                                )
                            let _ = { startAngle += angle }()
                        }
                    }
                    .frame(width: min(geo.size.width, geo.size.height), height: min(geo.size.width, geo.size.height))
                    .shadow(color: .gray.opacity(0.2), radius: 5)
                }
                .frame(height: 200)
                
                legend
            }
        }
    }
    
    var legend: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(slices, id: \.category) { slice in
                HStack {
                    Circle()
                        .fill(slice.color)
                        .frame(width: 12, height: 12)
                    Text(slice.category)
                        .font(.system(.subheadline, design: .rounded))
                    Spacer()
                    Text(String(format: "%.1f%%", (slice.value / total) * 100))
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                }
            }
        }
        .padding(.horizontal)
    }
    
    struct PieSlice: Shape {
        var startAngle: Angle
        var endAngle: Angle
        
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let center = CGPoint(x: rect.midX, y: rect.midY)
            path.move(to: center)
            path.addArc(center: center, radius: rect.width / 2, startAngle: startAngle, endAngle: endAngle, clockwise: false)
            return path
        }
    }
}

// LineChartView
struct LineChartView: View {
    let data: [(date: Date, amount: Double)]
    private var maxValue: Double { data.map { $0.amount }.max() ?? 1 }
    private var minValue: Double { data.map { $0.amount }.min() ?? 0 }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Daily Expenses")
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.gray.opacity(0.8))
            
            if data.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundStyle(.gray.opacity(0.5))
                    Text("No Data Available")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.gray.opacity(0.7))
                }
                .frame(height: 200)
            } else {
                GeometryReader { geo in
                    let widthStep = geo.size.width / CGFloat(max(1, data.count - 1))
                    let heightScale = geo.size.height / CGFloat(maxValue - minValue + 0.01) // Avoid division by zero
                    
                    ZStack {
                        Path { path in
                            for (i, entry) in data.enumerated() {
                                let x = CGFloat(i) * widthStep
                                let y = geo.size.height - CGFloat((entry.amount - minValue) * heightScale)
                                if i == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(
                            LinearGradient(gradient: Gradient(colors: [.skyBlue, .coralRed]), startPoint: .leading, endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                        )
                        
                        Path { path in
                            for (i, entry) in data.enumerated() {
                                let x = CGFloat(i) * widthStep
                                let y = geo.size.height - CGFloat((entry.amount - minValue) * heightScale)
                                path.move(to: CGPoint(x: x, y: geo.size.height))
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                        .stroke(.gray.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [5]))
                        
                        ForEach(data.indices, id: \.self) { i in
                            let x = CGFloat(i) * widthStep
                            let y = geo.size.height - CGFloat((data[i].amount - minValue) * heightScale)
                            ZStack {
                                RoundedRectangle(cornerRadius: 100, style: .continuous)
                                    .fill(.white)
                                RoundedRectangle(cornerRadius: 100, style: .continuous)
                                    .stroke(Color.skyBlue, lineWidth: 2)
                            }
                            .frame(width: 10, height: 10)
                            .position(x: x, y: y)
                            .overlay(
                                Text(String(format: "$%.0f", data[i].amount))
                                    .font(.system(.caption, design: .rounded, weight: .semibold))
                                    .foregroundColor(.gray)
                                    .offset(y: -20)
                                    .opacity(data[i].amount == maxValue || data[i].amount == minValue ? 1 : 0)
                            )
                        }
                    }
                }
                .frame(height: 200)
                
                HStack {
                    ForEach(data, id: \.date) { entry in
                        Text(entry.date, format: .dateTime.month(.abbreviated).day())
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.gray.opacity(0.7))
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
}

// EggsView.swift
struct EggsView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showingAdd = false
    @State private var editingBatch: EggBatch?
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [.creamyWhite, .white.opacity(0.9)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                if viewModel.eggBatches.isEmpty {
                    placeholderView
                } else {
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                            ForEach(viewModel.eggBatches.sorted(by: { $0.collectionDate > $1.collectionDate })) { batch in
                                EggCell(batch: batch)
                                    .onTapGesture {
                                        editingBatch = batch
                                    }
                            }
                        }
                        .padding()
                        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.eggBatches)
                    }
                }
            }
            .navigationTitle("Egg Basket")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.grassGreen)
                    }
                }
            }
            .sheet(isPresented: $showingAdd) { AddEggView() }
            .sheet(item: $editingBatch) { batch in
                AddEggView(batch: batch)
            }
            .refreshable {
                viewModel.scheduleExpiryNotifications()
            }
        }
    }
    
    var placeholderView: some View {
        VStack(spacing: 16) {
            Image(systemName: "basket.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(.linearGradient(colors: [.gray.opacity(0.5), .gray], startPoint: .top, endPoint: .bottom))
            
            Text("No Eggs Yet")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundColor(.gray)
            
            Text("Tap the '+' button to add your first egg batch!")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button("Add Eggs") {
                showingAdd = true
            }
            .buttonStyle(ButtonStyleCustom())
            .padding(.horizontal, 40)
        }
        .modifier(PlaceholderStyle())
        .padding(.horizontal)
    }
}

// EggCell
struct EggCell: View {
    let batch: EggBatch
    @State private var scale = 1.0
    
    var body: some View {
        VStack(spacing: 8) {
            Text(batch.emoji)
                .font(.system(size: 40))
                .shadow(color: batch.color.opacity(0.3), radius: 3)
            
            Text("\(batch.quantity)")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(.linearGradient(colors: [batch.color, batch.color.opacity(0.7)], startPoint: .top, endPoint: .bottom))
            
            Text("Expires: \(batch.expiryDate, format: .dateTime.month(.abbreviated).day())")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.gray.opacity(0.7))
        }
        .frame(width: 90, height: 120)
        .background(.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: batch.color.opacity(0.3), radius: 4)
        .scaleEffect(scale)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(Double.random(in: 0...0.5))) {
                scale = 1.05
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    scale = 1.0
                }
            }
        }
    }
}

// AddEggView
struct AddEggView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    
    @State var batch: EggBatch
    var isEdit: Bool
    
    init(batch: EggBatch? = nil) {
        if let batch = batch {
            self.isEdit = true
            _batch = State(initialValue: batch)
        } else {
            self.isEdit = false
            let now = Date()
            let expiry = Calendar.current.date(byAdding: .day, value: 28, to: now) ?? now
            _batch = State(initialValue: EggBatch(quantity: 1, collectionDate: now, expiryDate: expiry))
        }
    }
    
    @State var quantity = 1
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Quantity")) {
                    Stepper("Quantity: \(batch.quantity)", value: $batch.quantity, in: 1...999)
                        .font(.system(.body, design: .rounded))
                    //                        .onChange(of: quantity) { new in
                    //                            batch.quantity = new
                    //                        }
                }
                
                Section(header: Text("Dates")) {
                    DatePicker("Collection Date", selection: $batch.collectionDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .onChange(of: batch.collectionDate) { newDate in
                            batch.expiryDate = Calendar.current.date(byAdding: .day, value: 28, to: newDate) ?? newDate
                        }
                    
                    DatePicker("Expiry Date", selection: $batch.expiryDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                }
            }
            .onAppear {
                quantity = batch.quantity
            }
            .navigationTitle(isEdit ? "Edit Batch" : "Add Eggs")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        // batch.quantity = quantity
                        if isEdit {
                            viewModel.updateEggBatch(batch)
                        } else {
                            viewModel.addEggBatch(batch)
                        }
                        dismiss()
                    }
                    .font(.system(.headline, design: .rounded))
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.system(.headline, design: .rounded))
                }
                if isEdit {
                    ToolbarItem(placement: .bottomBar) {
                        Button("Delete", role: .destructive) {
                            viewModel.deleteEggBatch(batch)
                            dismiss()
                        }
                        .font(.system(.headline, design: .rounded))
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

extension LoadingView {
    func checkNotificationAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                isNotif = true
            case .denied:
                if canAskAgain() {
                    isNotif = true
                }
                sendConfigRequest()
            case .authorized, .provisional, .ephemeral:
                sendConfigRequest()
            @unknown default:
                sendConfigRequest()
            }
        }
    }
    
    func canAskAgain() -> Bool {
        if let lastDenied = UserDefaults.standard.object(forKey: lastDeniedKey) as? Date {
            let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
            return lastDenied < threeDaysAgo
        }
        return true
    }
    
    func sendConfigRequest() {
        let configNoMoreRequestsKey = "config_no_more_requests"
        if UserDefaults.standard.bool(forKey: configNoMoreRequestsKey) {
            print("Config requests are disabled by flag, exiting sendConfigRequest")
            DispatchQueue.main.async {
                UserDefaults.standard.set(true, forKey: configNoMoreRequestsKey)
                UserDefaults.standard.synchronize()
                finishLoadingWithoutWebview()
            }
            return
        }

        guard let conversionDataJson = UserDefaults.standard.data(forKey: "conversion_data") else {
            print("Conversion data not found in UserDefaults")
            DispatchQueue.main.async {
                UserDefaults.standard.set(true, forKey: configNoMoreRequestsKey)
                UserDefaults.standard.synchronize()
                finishLoadingWithoutWebview()
            }
            return
        }

        guard let conversionDataRaw = try? JSONSerialization.jsonObject(with: conversionDataJson) as? [String: Any?] else {
            print("Failed to deserialize conversion data")
            DispatchQueue.main.async {
                UserDefaults.standard.set(true, forKey: configNoMoreRequestsKey)
                UserDefaults.standard.synchronize()
                finishLoadingWithoutWebview()
            }
            return
        }

        var sanitizedConversionData = [String: Any]()
        for (key, value) in conversionDataRaw {
            if let value = value {
                sanitizedConversionData[key] = value
            } else {
                sanitizedConversionData[key] = NSNull()
            }
        }

        guard JSONSerialization.isValidJSONObject(sanitizedConversionData) else {
            print("Conversion data is not a valid JSON object")
            DispatchQueue.main.async {
                UserDefaults.standard.set(true, forKey: configNoMoreRequestsKey)
                UserDefaults.standard.synchronize()
                finishLoadingWithoutWebview()
            }
            return
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: sanitizedConversionData, options: [])
            let url = URL(string: "https://eggkeeperchickfarm.com/config.php")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Request error: \(error)")
                    DispatchQueue.main.async {
                        UserDefaults.standard.set(true, forKey: configNoMoreRequestsKey)
                        UserDefaults.standard.synchronize()
                        finishLoadingWithoutWebview()
                    }
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Invalid response")
                    DispatchQueue.main.async {
                        UserDefaults.standard.set(true, forKey: configNoMoreRequestsKey)
                        UserDefaults.standard.synchronize()
                        finishLoadingWithoutWebview()
                    }
                    return
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    print("Server returned status code \(httpResponse.statusCode)")
                    DispatchQueue.main.async {
                        UserDefaults.standard.set(true, forKey: configNoMoreRequestsKey)
                        UserDefaults.standard.synchronize()
                        finishLoadingWithoutWebview()
                    }
                    return
                }

                if let data = data {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            print("Config response JSON: \(json)")
                            DispatchQueue.main.async {
                                handleConfigResponse(json)
                            }
                        }
                    } catch {
                        print("Failed to parse response JSON: \(error)")
                        DispatchQueue.main.async {
                            UserDefaults.standard.set(true, forKey: configNoMoreRequestsKey)
                            UserDefaults.standard.synchronize()
                            finishLoadingWithoutWebview()
                        }
                    }
                }
            }
            task.resume()
        } catch {
            print("Failed to serialize request body: \(error)")
            DispatchQueue.main.async {
                UserDefaults.standard.set(true, forKey: configNoMoreRequestsKey)
                UserDefaults.standard.synchronize()
                finishLoadingWithoutWebview()
            }
        }
    }
    
    func handleConfigResponse(_ jsonResponse: [String: Any]) {
        if let ok = jsonResponse["ok"] as? Bool, ok,
           let url = jsonResponse["url"] as? String,
           let expires = jsonResponse["expires"] as? TimeInterval {
            UserDefaults.standard.set(url, forKey: configUrlKey)
            UserDefaults.standard.set(expires, forKey: configExpiresKey)
            UserDefaults.standard.removeObject(forKey: configNoMoreRequestsKey)
            UserDefaults.standard.synchronize()
            
            self.url = URLModel(urlString: url)
            print("Config saved: url = \(url), expires = \(expires)")
            
        } else {
            UserDefaults.standard.set(true, forKey: configNoMoreRequestsKey)
            UserDefaults.standard.synchronize()
            print("No valid config or error received, further requests disabled")
            finishLoadingWithoutWebview()
        }
    }
    
    func finishLoadingWithoutWebview() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isMain = true
        }
    }
}

// StatsView.swift
struct StatsView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showConfetti = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [.creamyWhite, .white.opacity(0.9)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                List {
                    eggStats
                    expenseStats
                    badgesSection
                    privacyPolicySection
                }
                .listStyle(.grouped)
                .scrollContentBackground(.hidden)
                
                if showConfetti {
                    ConfettiView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .navigationTitle("Statistics")
            .onAppear {
                if !viewModel.badges.filter({ $0.achieved }).isEmpty {
                    showConfetti = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation(.easeOut) {
                            showConfetti = false
                        }
                    }
                }
            }
        }
    }
    
    var eggStats: some View {
        Section(header: Text("Eggs").font(.system(.headline, design: .rounded)).foregroundColor(.skyBlue)) {
            if viewModel.totalEggsInBasket == 0 {
                HStack {
                    Image(systemName: "oval.fill")
                        .foregroundColor(.gray.opacity(0.5))
                    Text("No eggs collected yet")
                        .foregroundColor(.gray.opacity(0.7))
                        .font(.system(.subheadline, design: .rounded))
                    Spacer()
                }
            } else {
                LabeledContent("Collected This Week", value: "\(viewModel.eggsCollectedThisWeek)")
                    .font(.system(.subheadline, design: .rounded))
                LabeledContent("Collected This Month", value: "\(viewModel.eggsCollectedThisMonth)")
                    .font(.system(.subheadline, design: .rounded))
                LabeledContent("Fresh Eggs", value: "\(viewModel.freshEggs)")
                    .font(.system(.subheadline, design: .rounded))
            }
        }
    }
    
    var expenseStats: some View {
        Section(header: Text("Expenses").font(.system(.headline, design: .rounded)).foregroundColor(.coralRed)) {
            if viewModel.totalExpenses == 0 {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.gray.opacity(0.5))
                    Text("No expenses recorded yet")
                        .foregroundColor(.gray.opacity(0.7))
                        .font(.system(.subheadline, design: .rounded))
                    Spacer()
                }
            } else {
                LabeledContent("Total Cost", value: String(format: "$%.2f", viewModel.totalExpenses))
                    .font(.system(.subheadline, design: .rounded))
                LabeledContent("Cost per Egg", value: String(format: "$%.2f", viewModel.averageCostPerEgg))
                    .font(.system(.subheadline, design: .rounded))
            }
        }
    }
    
    var badgesSection: some View {
        Section(header: Text("Badges").font(.system(.headline, design: .rounded)).foregroundColor(.eggYellow)) {
            if viewModel.badges.allSatisfy({ !$0.achieved }) {
                HStack {
                    Image(systemName: "rosette")
                        .foregroundColor(.gray.opacity(0.5))
                    Text("No badges earned yet")
                        .foregroundColor(.gray.opacity(0.7))
                        .font(.system(.subheadline, design: .rounded))
                    Spacer()
                }
            } else {
                ForEach(viewModel.badges, id: \.name) { badge in
                    HStack {
                        Image(systemName: badge.icon)
                            .foregroundColor(badge.achieved ? .eggYellow : .gray.opacity(0.5))
                            .font(.system(size: 24))
                        Text(badge.name)
                            .foregroundColor(badge.achieved ? .primary : .secondary)
                            .font(.system(.subheadline, design: .rounded))
                        Spacer()
                        if badge.achieved {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.linearGradient(colors: [.grassGreen, .skyBlue], startPoint: .top, endPoint: .bottom))
                        }
                    }
                    .padding(.vertical, 4)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: badge.achieved)
                }
            }
        }
    }
    
    var privacyPolicySection: some View {
        Section(header: Text("Privacy Policy").font(.system(.headline, design: .rounded)).foregroundColor(.eggYellow)) {
            Button(action: {
                if let url = URL(string: "https://eggkeeperchickfarm.com/privacy-policy.html") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "shield")
                        .foregroundColor(.eggYellow)
                        .font(.system(size: 24))
                    Text("Privacy Policy")
                        .foregroundColor(.primary)
                        .font(.system(.subheadline, design: .rounded))
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(.eggYellow)
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// ConfettiView
struct ConfettiView: View {
    var body: some View {
        GeometryReader { geo in
            ForEach(0..<50) { i in
                ZStack {
                    Circle()
                        .fill([Color.eggYellow, .coralRed, .skyBlue, .grassGreen].randomElement()!)
                        .frame(width: 10, height: 10)
                    Rectangle()
                        .fill([Color.eggYellow, .coralRed, .skyBlue, .grassGreen].randomElement()!)
                        .frame(width: 8, height: 12)
                        .rotationEffect(.degrees(Double.random(in: 0...360)))
                }
                .position(x: .random(in: 0...geo.size.width), y: .random(in: 0...geo.size.height))
                .offset(y: -geo.size.height)
                .animation(
                    .easeOut(duration: 2.5)
                    .delay(Double(i) / 50)
                    .repeatCount(1),
                    value: UUID()
                )
                .offset(y: geo.size.height)
            }
        }
        .ignoresSafeArea()
        .blendMode(.plusLighter)
    }
}

#Preview {
    ContentView()
}
