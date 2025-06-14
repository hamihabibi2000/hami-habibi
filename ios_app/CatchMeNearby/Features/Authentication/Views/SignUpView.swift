import SwiftUI

struct SignUpView: View {
    @StateObject private var viewModel = AuthenticationViewModel()
    @Environment(\.presentationMode) var presentationMode // To dismiss the sheet

    var body: some View {
        NavigationView { // Or NavigationStack for iOS 16+
            VStack(spacing: 20) {
                Text("Sign Up")
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

                Button("Sign Up") {
                    viewModel.signUp()
                    // Consider dismissing the view upon successful signup,
                    // which would happen if userSession changes and RootView reacts.
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.primaryAccentPurple)
                .foregroundColor(Color.primaryTextWhite)
                .font(.headline)
                .cornerRadius(8)

                Button("Already have an account? Login") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(Color.secondaryTextCyan)
                .padding(.top)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.primaryBackgroundBlack.ignoresSafeArea())
            .navigationBarTitle("Create Account", displayMode: .inline) // Optional: For NavigationView context
            .toolbar { // For NavigationView context
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Dismiss") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Color.secondaryTextCyan)
                }
            }
            // This view is typically presented as a sheet or navigated to.
            // If userSession changes after signup, RootView will switch the main view.
        }
        .accentColor(Color.primaryAccentPurple)
        // Listen for user session changes to potentially dismiss automatically
        .onReceive(viewModel.$userSession) { userSession in
            if userSession != nil {
                // User successfully signed up and logged in
                presentationMode.wrappedValue.dismiss() // Dismiss the SignUp sheet
            }
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
