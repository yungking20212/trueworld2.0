import UIKit
import Stripe
import StripeApplePay
import PassKit

class CheckoutViewController: UIViewController, ApplePayContextDelegate {
    let applePayButton: PKPaymentButton = PKPaymentButton(paymentButtonType: .plain, paymentButtonStyle: .black)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Premium Neural Layout
        view.backgroundColor = .clear
        view.addSubview(applePayButton)
        applePayButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            applePayButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            applePayButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            applePayButton.widthAnchor.constraint(equalToConstant: 280),
            applePayButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Only offer Apple Pay if the customer can pay with it
        applePayButton.isHidden = !StripeAPI.deviceSupportsApplePay()
        applePayButton.addTarget(self, action: #selector(handleApplePayButtonTapped), for: .touchUpInside)
    }

    @objc func handleApplePayButtonTapped() {
        let merchantIdentifier = StripeConfig.appleMerchantId
        let paymentRequest = StripeAPI.paymentRequest(withMerchantIdentifier: merchantIdentifier, country: "US", currency: "USD")

        // Configure the line items on the payment request
        // In production, the label should be your registered Company Name
        paymentRequest.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "Trueworld 2.0", amount: 50.00),
        ]
        // Initialize an STPApplePayContext instance
        if let applePayContext = STPApplePayContext(paymentRequest: paymentRequest, delegate: self) {
            // Present Apple Pay payment sheet
            applePayContext.presentApplePay(on: self)
        } else {
            // There is a problem with your Apple Pay configuration:
            // Ensure you have configured your Apple Pay Merchant ID in Stripe and Apple, 
            // and have enabled Apple Pay in your project's Signing & Capabilities.
            print("NEURAL_VAULT_ERR: Apple Pay config locked.")
        }
    }
    
    // MARK: - ApplePayContextDelegate
    
    func applePayContext(_ context: STPApplePayContext, didCreatePaymentMethod paymentMethod: StripeAPI.PaymentMethod, paymentInformation: PKPayment) async throws -> String {
        // Production: Retrieve the PaymentIntent client secret from your Supabase Edge Function
        // We use the StripeService to prepare the payment context
        let userId = ProfileManager.shared.currentUser?.id ?? UUID()
        let amount = 5000 // In cents (mapping to the $50.00 summary item)
        
        do {
            let (secret, _, _) = try await StripeService.shared.preparePaymentSheet(userId: userId, amountCents: amount)
            return secret
        } catch {
            print("NEURAL_VAULT_ERR: Backend intent sync failed.")
            throw error
        }
    }
    
    func applePayContext(_ context: STPApplePayContext, didCompleteWith status: STPApplePayContext.PaymentStatus, error: Error?) {
        switch status {
        case .success:
            // Neural Victory: Trigger haptic success and notify UI
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            print("NEURAL_SYNC_SUCCESS: Story unlocked.")
            
        case .error:
            // Neural Failure: Handle the error gracefully
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            print("NEURAL_SYNC_ERR: Payment failed - \(error?.localizedDescription ?? "Unknown")")
            
        case .userCancellation:
            // User backed out of the vault
            print("NEURAL_VAULT_CANCELED: Identity retained.")
            
        @unknown default:
            print("NEURAL_PROTOCOL_BREAK: Unexpected payment state.")
            break
        }
    }
}
