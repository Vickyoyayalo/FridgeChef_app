//
//  LoginDetailView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/16.
//

import SwiftUI
import AuthenticationServices
import Firebase
import CryptoKit
import FirebaseAuth

struct LoginDetailView: View {
    @StateObject private var loginViewModel = LoginDetailViewModel()
    @StateObject private var userViewModel = UserViewModel()
    @State private var navigateToHome = false
    @State private var navigateToForgotPassword = false
    @State private var isLoggedIn = false
    @State private var errorMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var nonce: String?
    @Environment(\.colorScheme) private var scheme
    @AppStorage("log_Status") private var logStatus: Bool = false
    
    var body: some View {
        CustomNavigationBarView(title: "") {
            ZStack(alignment: .topLeading) {
                VStack(spacing: 15) {
                    Image("FridgeChefLogo")
                        .resizable()
                        .scaledToFit()
                        .padding(.vertical, -100)
                        .padding(.top, -100)
                    
                    TextField("Email", text: $loginViewModel.email)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                        .shadow(radius: 5)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)

                    SecureField("Password", text: $loginViewModel.password)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                        .shadow(radius: 5)
                    
                    Button(action: {
                        loginWithEmailPassword()
                    }) {
                        Text("Sign In")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                            .cornerRadius(8)
                            .shadow(radius: 5)
                    }
                    NavigationLink(destination: MainTabView(), isActive: $navigateToHome) {
                        EmptyView()
                    }
                    // 忘記密碼按鈕
                    Button(action: {
                        navigateToForgotPassword = true
                    }) {
                        Text("Forget Password?")
                            .foregroundColor(
                                Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                            .frame(maxWidth: .infinity)
                            .fontWeight(.bold)
                            .padding()
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(
                                Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange), lineWidth: 2))
                            .shadow(radius: 5)
                    }
                    .sheet(isPresented: $navigateToForgotPassword) {
                        ForgotPasswordView()
                    }
                    
                    Text("Or sign up with")
                        .font(.custom("ArialRoundedMTBold", size: 15))
                        .foregroundColor(.gray)
                    
                    // Apple Sign In
                    SignInWithAppleButton(.signIn) { request in
                        let nonce = randomNonceString()
                        self.nonce = nonce
                        request.requestedScopes = [.email, .fullName]
                        request.nonce = sha256(nonce)
                    } onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            loginWithFirebase(authorization)
                        case .failure(let error):
                            showError(error.localizedDescription)
                        }
                    }
                    .frame(height: 45)
                    .clipShape(.capsule)
                    .overlay {
                        ZStack {
                            Capsule()
                            HStack {
                                Image(systemName: "applelogo")
                                Text("Sign in with Apple")
                            }
                            .foregroundStyle(scheme == .dark ? .black : .white)
                        }
                        .allowsHitTesting(false)
                    }
                }
                .padding()
                Image("Loginmonster")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 250, height: 300)
                    .offset(x: 70, y: 400)
            }
        }
        .alert(errorMessage, isPresented: $showAlert) {}
        .overlay {
            if isLoggedIn {
                LoadingScreen()
            }
        }
        .alert(isPresented: $loginViewModel.showAlert) {
            Alert(title: Text("Error"), message: Text(loginViewModel.alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    // Email & Password log in
    func loginWithEmailPassword() {
        isLoggedIn = true
        Auth.auth().signIn(withEmail: loginViewModel.email, password: loginViewModel.password) { authResult, error in
            if let error = error {
                showError(error.localizedDescription)
                isLoggedIn = false
                return
            }
            logStatus = true
            isLoggedIn = false
            navigateToHome = true
        }
    }
    
    func showError(_ message: String) {
        errorMessage = message
        showAlert.toggle()
        isLoggedIn = false
    }
    
    func loginWithFirebase(_ authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            
            guard let nonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                showError("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                showError("Unable to serialize token string from data")
                return
            }
            
            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString, rawNonce: nonce, fullName: appleIDCredential.fullName)
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    showError(error.localizedDescription)
                    return
                }
                logStatus = true
                isLoggedIn = false
                navigateToHome = true
               
                if let user = Auth.auth().currentUser {
                    print("User is logged in with UID: \(user.uid)")
                   
                    let userData: [String: Any] = [
                        "email": user.email ?? "No Email",
                        "name": appleIDCredential.fullName?.givenName ?? "Anonymous"
                    ]
                    
                    FirestoreService().saveUser(userData, uid: user.uid) { result in
                        switch result {
                        case .success():
                            print("User data successfully saved to Firestore.")
                        case .failure(let error):
                            print("Failed to save user data: \(error.localizedDescription)")
                        }
                    }
                } else {
                    print("No user is currently logged in.")
                }
            }
        }
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] =
               Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

               let nonce = randomBytes.map { byte in
                   charset[Int(byte) % charset.count]
               }
       
               return String(nonce)
           }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.map { String(format: "%02x", $0) }.joined()
    }
    
    @ViewBuilder
    func LoadingScreen() -> some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
            ProgressView()
                .frame(width: 45, height: 45)
                .background(.background, in: .rect(cornerRadius: 5))
        }
    }
}

#Preview {
    LoginDetailView()
}
