import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    // Environment variable to dismiss the view if presented modally
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 30)

                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                TextField("Username", text: $username)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                SecureField("Confirm Password", text: $confirmPassword)
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
                    // Basic validation
                    if password != confirmPassword {
                        authViewModel.errorMessage = "Passwords do not match."
                        return
                    }
                    if email.isEmpty || username.isEmpty || password.isEmpty {
                        authViewModel.errorMessage = "All fields are required."
                        return
                    }
                    authViewModel.signUp(email: email, username: username, password: password)
                }) {
                    Text("Sign Up")
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
                    // Action to navigate to LoginView (assuming it exists)
                    // This might be handled by a parent view that switches between SignUp and Login
                    print("Navigate to Login Tapped - Implement navigation")
                    presentationMode.wrappedValue.dismiss() // Example: dismiss if presented modally
                }) {
                    HStack {
                        Text("Already have an account?")
                        Text("Log In").fontWeight(.bold)
                    }
                    .foregroundColor(.blue) // Accent color
                }
                .padding(.bottom)
            }
            .padding(.horizontal, 30)
            .navigationBarHidden(true) // Hide navigation bar for a cleaner look
            .onReceive(authViewModel.$userSession) { userSession in
                if userSession != nil {
                    // Successfully signed up and user session created
                    // Could navigate to main app content view here
                    print("DEBUG: SignUpView detected user session, potentially navigate to main view.")
                    // presentationMode.wrappedValue.dismiss() // Or navigate to home
                }
            }
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView().environmentObject(AuthViewModel()) // Provide a mock AuthViewModel for preview
    }
}
