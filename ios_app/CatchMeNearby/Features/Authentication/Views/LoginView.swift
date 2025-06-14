import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthenticationViewModel()
    // For navigation to SignUpView. In a real app, this would be part of a NavigationStack.
    @State private var showSignUpView = false

    var body: some View {
        NavigationView { // Or NavigationStack for iOS 16+
            VStack(spacing: 20) {
                Text("Login")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.primaryTextWhite)

                TextField("Email", text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color.secondaryBackgroundDarkGray)
                    .foregroundColor(Color.primaryTextWhite)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primaryAccentPurple, lineWidth: 1))

                SecureField("Password", text: $viewModel.password)
                    .padding()
                    .background(Color.secondaryBackgroundDarkGray)
                    .foregroundColor(Color.primaryTextWhite)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primaryAccentPurple, lineWidth: 1))

                if let message = viewModel.errorMessage {
                    Text(message)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }

                Button("Login") {
                    viewModel.login()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.primaryAccentPurple)
                .foregroundColor(Color.primaryTextWhite)
                .font(.headline)
                .cornerRadius(8)

                HStack {
                    Text("Don't have an account?")
                        .foregroundColor(Color.primaryTextWhite)
                    Button("Sign Up") {
                        showSignUpView = true
                    }
                    .foregroundColor(Color.secondaryTextCyan)
                }
                .padding(.top)

            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.primaryBackgroundBlack.ignoresSafeArea())
            .sheet(isPresented: $showSignUpView) {
                SignUpView() // Present SignUpView as a sheet
                    .environmentObject(viewModel) // Pass the same viewModel or a new one if preferred
            }
            // In a real app using NavigationStack, you'd use NavigationLink
            // .navigationDestination(isPresented: $showSignUpView) { SignUpView() }
        }
        .accentColor(Color.primaryAccentPurple) // For navigation view elements like back button
        // This view itself is presented by RootView when user is not authenticated.
        // RootView's authViewModel.userSession will trigger a change, dismissing this implicitly.
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
