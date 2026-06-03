// ContentView.swift — Root app + LoginView
// iOS 18 SwiftUI: @main, TabView .sidebarAdaptable

import SwiftUI
import SwiftData

@main struct CoworkersApp: App {
    @State private var vm = AppViewModel.shared
    var body: some Scene {
        WindowGroup {
            ContentView().environment(vm).modelContainer(.coworkers)
        }
    }
}

struct ContentView: View {
    var body: some View {
        if AuthService.shared.isAuthenticated { MainTabView() } else { LoginView() }
    }
}

struct MainTabView: View {
    @Environment(AppViewModel.self) private var vm
    @Bindable private var bvm = AppViewModel.shared
    var body: some View {
        TabView(selection: $bvm.tab) {
            Tab("Chats",  systemImage:"bubble.left.and.bubble.right.fill", value:AppTab.conversations) { ConversationsView() }
            Tab("Memory", systemImage:"brain.head.profile.fill",           value:AppTab.memory)        { MemoryView() }
        }
        .tabViewStyle(.sidebarAdaptable)
        .task { await vm.loadAll() }
        .alert("Error", isPresented:.constant(vm.error != nil)) {
            Button("OK") { bvm.error = nil }
        } message: { Text(vm.error ?? "") }
    }
}

struct LoginView: View {
    @State private var email = ""; @State private var loading = false; @State private var error: String?
    var body: some View {
        ZStack {
            Color(red:0.035,green:0.035,blue:0.043).ignoresSafeArea()
            VStack(spacing:0) {
                Spacer()
                VStack(alignment:.leading, spacing:20) {
                    HStack(spacing:0) {
                        Text("managed").font(.system(size:24,weight:.semibold,design:.monospaced)).foregroundStyle(.white)
                        Text("coworkers").font(.system(size:24,weight:.semibold,design:.monospaced)).foregroundStyle(Color(red:0.851,green:0.467,blue:0.024))
                    }
                    Label("Workers AI · Llama 3.1 8B · No API key", systemImage:"bolt.fill")
                        .font(.system(size:11,design:.monospaced))
                    if let e = error { Text(e).font(.system(size:12)).foregroundStyle(.red) }
                    VStack(alignment:.leading, spacing:5) {
                        Text("EMAIL").font(.system(size:11,weight:.semibold,design:.monospaced)).tracking(1)
                        TextField("alex@jadecli.com", text:$email)
                            .textFieldStyle(.plain).font(.system(size:15))
                            .keyboardType(.emailAddress).textInputAutocapitalization(.never).autocorrectionDisabled()
                            .padding(11).background(.black).cornerRadius(8)
                    }
                    Button { Task { await signIn() } } label: {
                        Group { if loading { ProgressView().tint(.black) } else { Text("Sign in →").fontWeight(.semibold) } }
                            .frame(maxWidth:.infinity).padding(13).background(Color(red:0.851,green:0.467,blue:0.024)).foregroundStyle(.black).cornerRadius(8)
                    }.disabled(email.isEmpty || loading)
                }
                .padding(32).background(Color(red:0.094,green:0.094,blue:0.106))
                .cornerRadius(16).padding(.horizontal,20)
                Spacer()
            }
        }
    }
    private func signIn() async {
        loading=true; error=nil
        do { try await AuthService.shared.login(email:email) } catch { self.error=error.localizedDescription }
        loading=false
    }
}