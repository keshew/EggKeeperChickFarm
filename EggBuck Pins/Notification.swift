import SwiftUI

struct NotificationView: View {
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.presentationMode) var presentationMode
    
    private let lastDeniedKey = "lastNotificationDeniedDate"
    
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
                            Text("ALLOW NOTIFICATIONS ABOUT BONUSES AND PROMOS")
                                .font(.custom("PassionOne-Bold", size: 24))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white)
                            
                            Text("Stay tuned with best offers from our casino")
                                .font(.custom("PassionOne-Regular", size: 18))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Color(red: 186/255, green: 186/255, blue: 185/255))
                        }
                        .padding(.horizontal, 40)
                        
                        VStack(spacing: 20) {
                            Button(action: {
                                requestNotificationPermission()
                            }) {
                                Image("bonuses")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 250, height: 55)
                            }
                            
                            Button(action:{
                                saveDeniedDate()
                                presentationMode.wrappedValue.dismiss()
                                NotificationCenter.default.post(name: .notificationPermissionResult, object: nil, userInfo: ["granted": true])
                            }) {
                                Text("Skip")
                                    .font(.custom("PassionOne-Regular", size: 18))
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(Color(red: 186/255, green: 186/255, blue: 185/255))
                            }
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
                        
                        VStack(spacing: 20) {
                            Text("ALLOW NOTIFICATIONS ABOUT BONUSES AND PROMOS")
                                .font(.custom("PassionOne-Bold", size: 24))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white)
                            
                            Text("Stay tuned with best offers from our casino")
                                .font(.custom("PassionOne-Regular", size: 18))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Color(red: 186/255, green: 186/255, blue: 185/255))
                        }
                        .padding(.horizontal, 40)
                        
                        VStack(spacing: 10) {
                            Button(action: {
                                requestNotificationPermission()
                            }) {
                                Image("bonuses")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 250, height: 55)
                            }
                            
                            Button(action:{
                                saveDeniedDate()
                                presentationMode.wrappedValue.dismiss()
                                NotificationCenter.default.post(name: .notificationPermissionResult, object: nil, userInfo: ["granted": true])
                            }) {
                                Text("Skip")
                                    .font(.custom("PassionOne-Regular", size: 18))
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(Color(red: 186/255, green: 186/255, blue: 185/255))
                            }
                        }
                    }
                    .padding(.bottom, 190)
                }
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                    if granted {
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .notificationPermissionResult, object: nil, userInfo: ["granted": true])
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                        presentationMode.wrappedValue.dismiss()
                    } else {
                        saveDeniedDate()
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .notificationPermissionResult, object: nil, userInfo: ["granted": false])
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            case .denied:
                presentationMode.wrappedValue.dismiss()
            case .authorized, .provisional, .ephemeral:
                print("razresheni")
            @unknown default:
                break
            }
        }
    }
    
    private func saveDeniedDate() {
        UserDefaults.standard.set(Date(), forKey: lastDeniedKey)
        print("Saved last denied date: \(Date())")
    }
}

#Preview {
    NotificationView()
}
