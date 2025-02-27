//
//  signinViewController.swift
//  trendrise
//
//  Created by Analee Maharaj on 12/1/24.
//

import UIKit
import CoreData
//empty table of accounts
var data = [Members]()
class signinViewController: UIViewController {
    
//    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    private lazy var context: NSManagedObjectContext = {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
    }
    
    @IBOutlet weak var email: UITextField!
    
    @IBOutlet weak var password: UITextField!
    
    @IBAction func loginbtn(_ sender: UIButton) {
        
        // Validate input
               guard let emailText = email.text, !emailText.isEmpty,
                     let passwordText = password.text, !passwordText.isEmpty else {
                   showAlert(message: "Please enter both email and password")
                   return
               }
               
               // Authenticate user
               if authenticateUser(email: emailText, password: passwordText) {
                   let mainStroyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                       let OptionsVC : UIViewController = mainStroyboard.instantiateViewController(withIdentifier: "OptionsVC") as UIViewController
                       //perform actions
                       self.present(OptionsVC, animated: true, completion:nil)
                       return               } else {
                   showAlert(message: "Invalid email or password")
               }
           }
//           
    private func authenticateUser(email: String, password: String) -> Bool {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            showAlert(message: "Could not authenticate")
            return false
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        // Fetch request to find user with matching email
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Members")
        fetchRequest.predicate = NSPredicate(format: "email == %@", email)
        
        do {
            let results = try managedContext.fetch(fetchRequest)
            
            // Print results for debugging
            print("Fetch results: \(results)")
            print("Number of results: \(results.count)")
            
            // Check if any users found
            guard let existingUser = results.first as? NSManagedObject else {
                print("No user found with email: \(email)")
                return false
            }
            
            // Retrieve stored hashed password
            guard let storedPassword = existingUser.value(forKey: "password") as? String else {
                print("No password found for user")
                return false
            }
            
            // Compare hashed passwords
            let isAuthenticated = storedPassword == hashPassword(password)
            print("Authentication result: \(isAuthenticated)")
            return isAuthenticated
        } catch {
            print("Authentication error: \(error)")
            showAlert(message: "Authentication failed")
            return false
        }
    }
    func registerUser(email: String, password: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            showAlert(message: "Could not register user")
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        // Create new managed object
        guard let entity = NSEntityDescription.entity(forEntityName: "Members", in: managedContext) else {
            showAlert(message: "Could not create user entity")
            return
        }
        
        let user = NSManagedObject(entity: entity, insertInto: managedContext)
        
        // Set user properties
        user.setValue(email, forKey: "email")
        user.setValue(hashPassword(password), forKey: "password")
        
        do {
            try managedContext.save()
            print("User registered successfully")
        } catch {
            print("Could not save user: \(error)")
            showAlert(message: "Registration failed")
        }
    }
    


       private func showAlert(message: String) {
           let alertController = UIAlertController(title: "Authentication", message: message, preferredStyle: .alert)
           alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
           present(alertController, animated: true, completion: nil)
       }

    }
