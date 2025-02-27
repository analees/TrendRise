//
//  registrationViewController.swift
//  trendrise
//
//  Created by Analee Maharaj on 12/1/24.
//

import UIKit
import CoreData

class registrationViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        fullname.delegate = self
        email.delegate = self
        password.delegate = self
        confirmpassword.delegate = self

    }
    
    
    @IBOutlet weak var fullname: UITextField!
    
    @IBOutlet weak var email: UITextField!
    
    @IBOutlet weak var password: UITextField!
    
    @IBOutlet weak var confirmpassword: UITextField!
    

    @IBAction func registerbutton(_ sender: UIButton) {
        guard let name = fullname.text, !name.isEmpty,
              let emailText = email.text, !emailText.isEmpty,
              let passwordText = password.text, !passwordText.isEmpty,
              let confirmPasswordText = confirmpassword.text, !confirmPasswordText.isEmpty else {
            showAlert(message: "All fields are required")
            return
        }
        
        // Validate email format
        guard isValidEmail(emailText) else {
            showAlert(message: "Invalid email format")
            return
        }
        
        // Check password match
        guard passwordText == confirmPasswordText else {
            showAlert(message: "Passwords do not match")
            return
        }
        
        // Validate password strength
        guard isValidPassword(passwordText) else {
            showAlert(message: "Password must be at least 8 characters long and contain a number and special character")
            return
        }

        // Save to Core Data
        if saveMemberToCoreData(name: name, email: emailText, password: passwordText) {
            // Navigate to OptionsViewController
            //                   navigateToOptionsViewController()
            
            guard let OptionsVC = storyboard?.instantiateViewController(withIdentifier: "OptionsVC") as? OptionsViewController else {
                print("Failed to instantiate LeaderboardViewController")
                return
            }
            
            
            present(OptionsVC, animated: true, completion: nil)
        }
    }
        
           }
           
           // Email validation function
           func isValidEmail(_ email: String) -> Bool {
               let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
               let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
               return emailPred.evaluate(with: email)
           }
           
           // Password strength validation
           func isValidPassword(_ password: String) -> Bool {
               // At least 8 characters, contains a number and a special character
               let passwordRegex = "^(?=.*[A-Za-z])(?=.*\\d)(?=.*[@$!%*#?&])[A-Za-z\\d@$!%*#?&]{8,}$"
               return NSPredicate(format:"SELF MATCHES %@", passwordRegex).evaluate(with: password)
           }
           
           // Save member to Core Data
           func saveMemberToCoreData(name: String, email: String, password: String) -> Bool {
               // Get the managed context
               guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                   showAlert(message: "Could not save member")
                   return false
               }
               
               let managedContext = appDelegate.persistentContainer.viewContext
               
               // Create new Members entity
               let entity = NSEntityDescription.entity(forEntityName: "Members", in: managedContext)!
               let member = NSManagedObject(entity: entity, insertInto: managedContext)
               
               // Set attributes
               member.setValue(name, forKey: "fullname")
               member.setValue(email, forKey: "email")
               
               // Hash password before storing (recommended for security)
               let hashedPassword = hashPassword(password)
               member.setValue(hashedPassword, forKey: "password")
               
               // Save the context
               do {
                   try managedContext.save()
                   return true
               } catch let error as NSError {
                   print("Could not save. \(error), \(error.userInfo)")
                   showAlert(message: "Registration Failed")
                   return false
               }
           }
        
           
           // performed password hashing
           func hashPassword(_ password: String) -> String {
               return password.hashValue.description
           }

           // Alert function
           func showAlert(message: String) {
               let alert = UIAlertController(title: "Error",
                                             message: message,
                                             preferredStyle: .alert)
               alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//               present(alert, animated: true, completion: nil)
           }
       

       extension registrationViewController: UITextFieldDelegate {
           func textFieldShouldReturn(_ textField: UITextField) -> Bool {
               // Move focus to next text field
               switch textField {
               case fullname:
                   email.becomeFirstResponder()
               case email:
                   password.becomeFirstResponder()
               case password:
                   confirmpassword.becomeFirstResponder()
               case confirmpassword:
                   textField.resignFirstResponder()
                   registerbutton(UIButton())
               default:
                   break
               }
               return true
           }
           
    
       }
