//
//  ViewController.swift
//  PayemtnDemo
//
//  Created by Subhra Roy on 01/10/19.
//  Copyright © 2019 Subhra Roy. All rights reserved.
//

import UIKit
import Stripe

struct Product {
    let print: String
    let price: Int
}


class ViewController: UIViewController {

    
    private var selectedPaymentOption : STPPaymentOption!
    private var paymentContext: STPPaymentContext!
    private var customerContext : STPCustomerContext!
    
    private var price = 5 {
        didSet {
            // Forward value to payment context
            paymentContext.paymentAmount = price
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
       
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
       
    }
    
    @IBAction func didTapToAddCard(_ sender: Any) {
        self.handleAddPaymentOptionButtonTapped()
      // self.presentPaymentMethodsViewController()
    }
    
    // MARK: Helpers
    
    private func presentPaymentMethodsViewController() {
        guard !STPPaymentConfiguration.shared().publishableKey.isEmpty else {
            // Present error immediately because publishable key needs to be set
            let message : String = "Please assign a value to `publishableKey` before continuing. See `AppDelegate.swift`."
            let errorAlert : UIAlertController = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertController.Style.alert)
            present(errorAlert, animated: true) {
                
            }
            return
        }
        
        guard let baseURL : String = StripeAPIKeyClient.sharedKeyClient.baseURLString, !baseURL.isEmpty else {
            // Present error immediately because base url needs to be set
            let message = "Please assign a value to `MainAPIClient.shared.baseURLString` before continuing. See `AppDelegate.swift`."
            let errorAlert : UIAlertController = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertController.Style.alert)
            present(errorAlert, animated: true) {
                
            }
            return
        }
        
        // Present the Stripe payment methods view controller to enter payment details
        paymentContext.presentPaymentOptionsViewController()
    }

    
    
    func handleAddPaymentOptionButtonTapped() {
        // Setup add card view controller
        let addCardViewController = STPAddCardViewController()
        addCardViewController.delegate = self
        
        // Present add card view controller
        let navigationController = UINavigationController(rootViewController: addCardViewController)
        present(navigationController, animated: true)
    }
    
    
    @IBAction func didTapToPayment(_ sender: Any) {
        //self.handlePaymentOptionsButtonTapped()
        self.presentPaymentMethodsViewController()
    }
    
}

extension ViewController : STPAddCardViewControllerDelegate{
    
    // MARK: STPAddCardViewControllerDelegate
    
    func addCardViewControllerDidCancel(_ addCardViewController: STPAddCardViewController) {
        // Dismiss add card view controller
        dismiss(animated: true)
    }
    
    func addCardViewController(_ addCardViewController: STPAddCardViewController, didCreatePaymentMethod paymentMethod: STPPaymentMethod, completion: @escaping STPErrorBlock) {
        
        print("\(String(describing: paymentMethod.card?.brand))")
        print("\(String(describing: paymentMethod.card?.checks?.cvcCheck))")
        print("\(String(describing: paymentMethod.card?.country))")
        print("\(String(describing: paymentMethod.card?.expMonth))")
        print("\(String(describing: paymentMethod.card?.expYear))")
        print("\(String(describing: paymentMethod.card?.allResponseFields))")
        print("\(String(describing: paymentMethod.card?.funding))")
        print("\(String(describing: paymentMethod.card?.last4))")
        
        print("\(String(describing: paymentMethod.customerId))")
        print("\(String(describing: paymentMethod.billingDetails))")
        print("\(String(describing: paymentMethod.stripeId))")
        
        dismiss(animated: true) { [unowned self] in 
            self.initiatePaymentOptions()
        }
        
        /*submitPaymentMethodToBackend(paymentMethod, completion: { (error: Error?) in
         if let error = error {
         // Show error in add card view controller
         completion(error)
         }
         else {
         // Notify add card view controller that PaymentMethod creation was handled successfully
         completion(nil)
         
         // Dismiss add card view controller
         dismiss(animated: true)
         }
         })*/
    }
    
    private  func initiatePaymentOptions() -> Void{
        
        // Setup customer context
        customerContext = STPCustomerContext(keyProvider: StripeAPIKeyClient.sharedKeyClient)
        paymentContext = STPPaymentContext(customerContext: customerContext)
        paymentContext.delegate = self
        paymentContext.hostViewController = self
        
    }
    
}

extension ViewController{
    
    func handlePaymentOptionsButtonTapped() {
        // Setup payment options view controller
        let paymentOptionsViewController = STPPaymentOptionsViewController(configuration: STPPaymentConfiguration.shared(), theme: STPTheme.default(), customerContext: customerContext, delegate: self)
        
        // Present payment options view controller
        let navigationController = UINavigationController(rootViewController: paymentOptionsViewController)
        present(navigationController, animated: true)
       
    }
    
}

extension ViewController : STPPaymentOptionsViewControllerDelegate{
    // MARK: STPPaymentOptionsViewControllerDelegate
    
    func paymentOptionsViewController(_ paymentOptionsViewController: STPPaymentOptionsViewController, didFailToLoadWithError error: Error) {
        // Dismiss payment options view controller
        dismiss(animated: true)
        
        // Present error to user...
    }
    
    func paymentOptionsViewControllerDidCancel(_ paymentOptionsViewController: STPPaymentOptionsViewController) {
        // Dismiss payment options view controller
        dismiss(animated: true)
    }
    
    func paymentOptionsViewControllerDidFinish(_ paymentOptionsViewController: STPPaymentOptionsViewController) {
        // Dismiss payment options view controller
        dismiss(animated: true)
    }
    
    func paymentOptionsViewController(_ paymentOptionsViewController: STPPaymentOptionsViewController, didSelect paymentOption: STPPaymentOption) {
        // Save selected payment option
        selectedPaymentOption = paymentOption
    }
    
}

extension ViewController : STPPaymentContextDelegate{
    
    func paymentContextDidChange(_ paymentContext: STPPaymentContext) {
         // Reload related UI components
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFailToLoadWithError error: Error) {
        
        if let customerKeyError = error as? StripeAPIKeyClient.CustomerKeyError {
            
            switch customerKeyError {
                case .missingBaseURL:
                    // Fail silently until base url string is set
                    print("[ERROR]: Please assign a value to `MainAPIClient.shared.baseURLString` before continuing. See `AppDelegate.swift`.")
                case .invalidResponse:
                    // Use customer key specific error message
                    print("[ERROR]: Missing or malformed response when attempting to `MainAPIClient.shared.createCustomerKey`. Please check internet connection and backend response formatting.")
                    
                    let errorAlert : UIAlertController = UIAlertController(title: "Alert", message: "Could not retrieve customer information", preferredStyle: UIAlertController.Style.alert)
                    
                    let okAction = UIAlertAction(title: "Ok", style: UIAlertAction.Style.cancel) { (action) in
                        // Retry payment context loading
                        paymentContext.retryLoading()
                    }
                    errorAlert.addAction(okAction)
                    present(errorAlert, animated: true) {
                    }
            }
        }
        else {
            // Use generic error message
            print("[ERROR]: Unrecognized error while loading payment context: \(error)");
            
            let errorAlert : UIAlertController = UIAlertController(title: "Alert", message: "Could not retrieve payment information", preferredStyle: UIAlertController.Style.alert)
            
            let okAction = UIAlertAction(title: "Ok", style: UIAlertAction.Style.cancel) { (action) in
                // Retry payment context loading
                paymentContext.retryLoading()
            }
            errorAlert.addAction(okAction)
            present(errorAlert, animated: true) {
            }
        }
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didCreatePaymentResult paymentResult: STPPaymentResult, completion: @escaping STPPaymentStatusBlock) {
        
        // Create charge using payment result
        let source = paymentResult.paymentMethod.stripeId
        let shippingMethod : PKShippingMethod = PKShippingMethod()
        shippingMethod.identifier = source
        shippingMethod.detail = paymentResult.paymentMethod.billingDetails?.address?.postalCode
        let clientSecret : String = Stripe.defaultPublishableKey() ?? ""
        
        StripeAPIKeyClient.sharedKeyClient.createPaymentIntent(source: source, products: [Product(print: "Gift Card", price: 5)], shippingMethod: shippingMethod, country: paymentResult.paymentMethod.billingDetails?.address?.country, completion: { (result) in
            
                    print("\(result)")
            })
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFinishWith status: STPPaymentStatus, error: Error?) {
        
        switch status {
            case .success:
                print("Payment done.")
            case .userCancellation:
                print("User cancelled the trnsaction")
            case .error :
                print("Error in payment.")
            default:
                print("Unkown.")
        }
    }
    
}
