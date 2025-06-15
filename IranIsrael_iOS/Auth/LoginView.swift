import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""

    // Environment variable to dismiss the view if presented modally
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Log In")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 30)

                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                if let errorMessage = authViewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.vertical)
                }

                Button(action: {
                    if email.isEmpty || password.isEmpty {
                        authViewModel.errorMessage = "Email and password are required."
                        return
                    }
                    authViewModel.login(email: email, password: password)
                }) {
                    Text("Log In")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue) // Accent color
                        .cornerRadius(8)
                }
                .padding(.top)

                Spacer()

                Button(action: {
                    // Action to navigate to SignUpView
                    // This might be handled by a parent view that switches between SignUp and Login
                    print("Navigate to Sign Up Tapped - Implement navigation")
                }) {
                    HStack {
                        Text("Don't have an account?")
                        Text("Sign Up").fontWeight(.bold)
                    }
                    .foregroundColor(.blue) // Accent color
                }
                .padding(.bottom)
            }
            .padding(.horizontal, 30)
            .navigationBarHidden(true) // Hide navigation bar for a cleaner look
            .onReceive(authViewModel.$userSession) { userSession in
                if userSession != nil {
                    print("DEBUG: LoginView detected user session, potentially navigate to main view.")
                }
            }
             .onAppear {
                authViewModel.errorMessage = nil // Clear previous error messages
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView().environmentObject(AuthViewModel())
    }
}
