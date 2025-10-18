import SwiftUI

struct URLModel: Identifiable, Equatable {
    let id = UUID()
    let urlString: String
}

struct LoadingView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var hasCheckedAuthorization = false
    @State  var url: URLModel? = nil
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State var conversionDataReceived: Bool = false
    @State var isNotif = false
    let lastDeniedKey = "lastNotificationDeniedDate"
    let configExpiresKey = "config_expires"
    let configUrlKey = "config_url"
    let configNoMoreRequestsKey = "config_no_more_requests"
    @State var isMain = false
    @State  var isRequestingConfig = false
    @StateObject  var networkMonitor = NetworkMonitor.shared
    @State var isInet = false
    @State private var hasHandledConversion = false
    
    var isPortrait: Bool {
        verticalSizeClass == .regular && horizontalSizeClass == .compact
    }
    
    var isLandscape: Bool {
        verticalSizeClass == .compact && horizontalSizeClass == .regular
    }
    
    var body: some View {
        VStack {
            if isPortrait {
                ZStack {
                    Image("BGforNotifications")
                        .resizable()
                        .ignoresSafeArea()
                        .aspectRatio(contentMode: .fill)
                    
                    VStack(spacing: 50) {
                        Spacer()
                        
                        VStack(spacing: 30) {
                            Spacer()
                            
                            Text("LOADING...")
                                .font(.custom("PassionOne-Bold", size: 24))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 40)
                            
                            ProgressView()
                        }
                    }
                    .padding(.vertical, 30)
                }
            } else {
                ZStack {
                    Image("BGforNotificationsLandscape")
                        .resizable()
                        .ignoresSafeArea()
                        .aspectRatio(contentMode: .fill)
                    
                    VStack(spacing: 30) {
                        Spacer()
                        
                        Text("LOADING...")
                            .font(.custom("PassionOne-Bold", size: 24))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 40)
                        
                        ProgressView()
                    }
                    .padding(.bottom, 190)
                }
            }
        }
        .onReceive(networkMonitor.$isDisconnected) { disconnected in
            if disconnected {
                isInet = true
            } else {
            }
        }
        .fullScreenCover(item: $url) { item in
            Detail(urlString: item.urlString)
                .ignoresSafeArea(.keyboard)
        }
        .onReceive(NotificationCenter.default.publisher(for: .datraRecieved)) { notification in
            DispatchQueue.main.async {
                guard !isInet else { return }
                if !hasHandledConversion {
                    let isOrganic = UserDefaults.standard.bool(forKey: "is_organic_conversion")
                    if isOrganic {
//                        isMain = true
                        checkNotificationAuthorization()
                    } else {
                        checkNotificationAuthorization()
                    }
                    hasHandledConversion = true
                } else {
                    print("Conversion event ignored due to recent handling")
                }
            }
        }
        
        .onReceive(NotificationCenter.default.publisher(for: .notificationPermissionResult)) { notification in
            sendConfigRequest()
        }
        .fullScreenCover(isPresented: $isNotif) {
            NotificationView()
        }
        .fullScreenCover(isPresented: $isMain) {
            ContentView()
        }
        .fullScreenCover(isPresented: $isInet) {
            NoInternet()
        }
    }
}

#Preview {
    LoadingView()
}
