import SwiftUI

struct URLModel: Identifiable, Equatable {
    let id = UUID()
    let urlString: String
}

struct LoadingView: View {
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
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                isInet = networkMonitor.isDisconnected
            }
        }
        .fullScreenCover(item: $url) { item in
            Detail(urlString: item.urlString)
        }
        .onReceive(NotificationCenter.default.publisher(for: .datraRecieved)) { notification in
            DispatchQueue.main.async {
                checkNotificationAuthorization()
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
            if UserDefaults.standard.string(forKey: configUrlKey) != nil {
                NoInternet()
            } else {
                ContentView()
            }
        }
    }
}

#Preview {
    LoadingView()
}
