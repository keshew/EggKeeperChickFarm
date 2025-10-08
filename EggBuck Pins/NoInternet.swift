import SwiftUI

struct NoInternet: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
 
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
                        
                        VStack(spacing: 20) {
                            Text("NO INTERNET CONNECTION")
                                .font(.custom("PassionOne-Bold", size: 24))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white)
                            
                            Text("Stay tuned with best offers from our casino")
                                .font(.custom("PassionOne-Regular", size: 18))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Color(red: 186/255, green: 186/255, blue: 185/255))
                                .hidden()
                        }
                        .padding(.horizontal, 40)
                        
                    
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
                        
                        VStack(spacing: 20) {
                            Text("NO INTERNET CONNECTION")
                                .font(.custom("PassionOne-Bold", size: 24))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white)
                            
                            Text("Stay tuned with best offers from our casino")
                                .font(.custom("PassionOne-Regular", size: 18))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Color(red: 186/255, green: 186/255, blue: 185/255))
                                .hidden()
                        }
                        .padding(.horizontal, 40)
                        
                      
                    }
                    .padding(.bottom, 190)
                }
            }
        }
    }
}

#Preview {
    NoInternet()
}

import Network
import Combine

final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor() 
    
    @Published private(set) var isDisconnected: Bool = false
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitorQueue")
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isDisconnected = (path.status != .satisfied)
            }
        }
        monitor.start(queue: queue)
    }
}
