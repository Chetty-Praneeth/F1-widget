import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    init() {
        // Custom tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.12, alpha: 1)
        appearance.shadowColor = .clear
        
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = UIColor(white: 0.4, alpha: 1)
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(white: 0.4, alpha: 1)]
        itemAppearance.selected.iconColor = UIColor(red: 0.88, green: 0.02, blue: 0.0, alpha: 1)
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(red: 0.88, green: 0.02, blue: 0.0, alpha: 1)]
        
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "flag.checkered")
                    Text("Home")
                }
                .tag(0)
            
            NavigationView {
                ScheduleView()
            }
            .tabItem {
                Image(systemName: "calendar")
                Text("Schedule")
            }
            .tag(1)
            
            StandingsView()
                .tabItem {
                    Image(systemName: "trophy.fill")
                    Text("Standings")
                }
                .tag(2)
            
            NavigationView {
                LiveResultsView()
            }
            .tabItem {
                Image(systemName: "antenna.radiowaves.left.and.right")
                Text("Live")
            }
            .tag(3)
        }
        .tint(F1Theme.f1Red)
    }
}
