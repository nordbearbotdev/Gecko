import UIKit

//-----------------------------------------------------------------------------------------------------------------------------------------------
class WelcomeView: UIViewController {

	//-------------------------------------------------------------------------------------------------------------------------------------------
	@IBAction func actionLoginEmail(_ sender: Any) {

		let loginEmailView = LoginEmailView()
		loginEmailView.delegate = self
		loginEmailView.isModalInPresentation = true
		loginEmailView.modalPresentationStyle = .fullScreen
		present(loginEmailView, animated: true)
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------
	@IBAction func actionRegisterEmail(_ sender: Any) {

		let registerEmailView = RegisterEmailView()
		registerEmailView.delegate = self
		registerEmailView.isModalInPresentation = true
		registerEmailView.modalPresentationStyle = .fullScreen
		present(registerEmailView, animated: true)
	}
}

// MARK: - LoginEmailDelegate
//-----------------------------------------------------------------------------------------------------------------------------------------------
extension WelcomeView: LoginEmailDelegate {

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func didLoginUserEmail() {

		dismiss(animated: true) {
			Users.loggedIn()
		}
	}
}

// MARK: - RegisterEmailDelegate
//-----------------------------------------------------------------------------------------------------------------------------------------------
extension WelcomeView: RegisterEmailDelegate {

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func didRegisterUser() {

		dismiss(animated: true) {
			Users.loggedIn()
		}
	}
}
