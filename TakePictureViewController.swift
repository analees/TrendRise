//
//  TakePictureViewController.swift
//  trendrise
//
//  Created by Analee Maharaj on 12/1/24.
import UIKit
import PhotosUI
import CoreData

//import librabries to analyse image
import CoreML
import Vision

//GLOBAL
//pointing to core data
let appdelegate = UIApplication.shared.delegate as! AppDelegate
//to go to core data must call context
let context = appdelegate.persistentContainer.viewContext

class TakePictureViewController: UIViewController, UIImagePickerControllerDelegate, PHPickerViewControllerDelegate, UINavigationControllerDelegate{
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func selectFromGallery(_ sender: UIButton) {
        print("Select from Gallery Button Pressed")
        
        var configuration = PHPickerConfiguration()
        configuration.filter = .images  // Only allow images to be picked
        configuration.selectionLimit = 1  // Limit to one image
        
        let pickerViewController = PHPickerViewController(configuration: configuration)
        pickerViewController.delegate = self
        self.present(pickerViewController, animated: true, completion: nil)
    }

    @IBAction func capture(_ sender: UIButton) {
        print("Button Pressed")
        
        //shows camera pp nothing else
        let imagePicker = UIImagePickerController()
        //brought back to the app
        imagePicker.delegate = self
        //check if camera is avaiable
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            imagePicker.sourceType = .camera
            
            //check if back or front camera
            if (UIImagePickerController.isCameraDeviceAvailable(.front)){
                imagePicker.cameraDevice = .front
            }
            else{
                imagePicker.cameraDevice = .rear
            }
            //loads phot app and only runs if phot is avaiable or line 57 will run
            self.present(imagePicker, animated: true, completion: nil)
        }//end if camera is avaible
        else{//if camera is not avaible then use photoalbumn
            var configuration = PHPickerConfiguration()
            //only select regular images from the albumn
            
            configuration.filter = .images
            //set the number of images the user can select if 0 that means unlimited
            configuration.selectionLimit = 1
            //pick image from photo albumn
            
            let pickerViewController = PHPickerViewController(configuration: configuration)
            pickerViewController.delegate = self
            //to present albumn
            present(pickerViewController, animated: true,completion: nil)
            
        }
        
    }
    
    
    @IBOutlet weak var imgImage: UIImageView!
    
    @IBAction func btnloadimg(_ sender: UIButton) {
        do {
                    let data = try context.fetch(Images.fetchRequest())
                    if let lastImageData = data.last?.imgattribute {
                        imgImage.image = UIImage(data: lastImageData)
                    } else {
                        showAlert(title: "Error", message: "No images found in Core Data.")
                    }
                } catch {
                    showAlert(title: "Error", message: "Failed to fetch images from Core Data.")
                }
            }

    
    @IBAction func btnsaveimg(_ sender: UIButton) {
        
        
        guard let image = imgImage.image else {
                showAlert(title: "Error", message: "No image to save.")
                return
            }
            
            // Analyze the image before saving
            analyzeImage(image)
        }


//php picker delegate
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
           picker.dismiss(animated: true, completion: nil)
           
           if let itemProvider = results.first?.itemProvider, itemProvider.canLoadObject(ofClass: UIImage.self) {
               itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                   if let error = error {
                       print(error.localizedDescription)
                       return
                   }
                   if let selectedImage = image as? UIImage {
                       DispatchQueue.main.async {
                           self.imgImage.image = selectedImage
                           self.analyzeImage(selectedImage)
                       }
                   }
               }
           }
       }
//image picker delegate
       func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
           picker.dismiss(animated: true, completion: nil)
           
           if let selectedImage = info[.originalImage] as? UIImage {
               imgImage.image = selectedImage
               analyzeImage(selectedImage) // Analyze the image
           }
       }
       
      //analyzes the image using coreML
       func analyzeImage(_ image: UIImage) {
           guard let model = try? VNCoreMLModel(for: ClothingClassifier_1().model) else {
               showAlert(title: "Error", message: "Failed to load the ML model.")
               return
           }

           let request = VNCoreMLRequest(model: model) { request, error in
               if let error = error {
                   print("Error during request: \(error.localizedDescription)")
                   self.showAlert(title: "Error", message: "Couldn't analyze the image.Try Again.")
                   return
               }
               
               guard let results = request.results as? [VNClassificationObservation],
                     let topResult = results.first else {
                   self.showAlert(title: "No Results", message: "The model could not classify the image.")
                   return
               }
               
               DispatchQueue.main.async {
                   self.showPredictionResult(topResult)
               }
           }

           guard let ciImage = CIImage(image: image) else {
               showAlert(title: "Error", message: "Could not convert UIImage to CIImage.")
               return
           }

           let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
           DispatchQueue.global(qos: .userInitiated).async {
               do {
                   try handler.perform([request])
               } catch {
                   print("Handler Error: \(error.localizedDescription)")
                   self.showAlert(title: "Error", message: "Image analysis failed.")
               }
           }
       }
    func showPredictionResult(_ result: VNClassificationObservation) {
        // Detect the dominant color from the image
        guard let image = self.imgImage.image,
              let dominantColor = getDominantColor(from: image) else {
            showAlert(title: "Error", message: "Could not determine the color of the item.")
            return
        }
        
        // Map the UIColor to a human color name
        let colorName = mapColorToName(dominantColor)
        
        // Combine the prediction identifier and color name
        let itemDescription = "\(result.identifier.capitalized) - \(colorName.capitalized)"
        
        let alert = UIAlertController(
            title: "Clothing Identified",
            message: "Is this correct?\n\(itemDescription)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
            print("User confirmed the prediction: \(itemDescription)")
            
            // Save the image to Core Data
            guard let imageData = image.pngData() else {
                self.showAlert(title: "Error", message: "No image to save.")
                return
            }
            
            let newImage = Images(context: context)
            newImage.imgattribute = imageData
            
            do {
                try context.save()
                print("Image successfully saved to Core Data.")
                
                // Navigate to RecommendationsViewController
                self.navigateToRecommendations(with: result.identifier, topConfidence: Double(result.confidence))
                
            } catch {
                self.showAlert(title: "Save Failed", message: "Failed to save the image. Please try again.")
                print("Core Data save error: \(error.localizedDescription)")
            }
        }))


        
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { _ in
            print("User denied the prediction")
            self.showAlert(title: "Save Cancelled", message: "The image was not saved.")
        }))
        
        self.present(alert, animated: true, completion: nil)
    }

    //function to convert the detected UIColor to a human name
    
    func mapColorToName(_ color: UIColor) -> String {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Simple thresholds for color categorization
        if red > 0.8 && green < 0.5 && blue < 0.5 {
            return "Red"
        } else if red < 0.5 && green > 0.8 && blue < 0.5 {
            return "Green"
        } else if red < 0.5 && green < 0.5 && blue > 0.8 {
            return "Blue"
        } else if red > 0.8 && green > 0.8 && blue < 0.5 {
            return "Yellow"
        } else if red > 0.8 && green > 0.8 && blue > 0.8 {
            return "White"
        } else if red < 0.2 && green < 0.2 && blue < 0.2 {
            return "Black"
        } else {
            //brown if it is an earthy color
            return "Brown"
        }
    }

    
    //identify the color
    func getDominantColor(from image: UIImage) -> UIColor? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: ciImage])
        guard let outputImage = filter?.outputImage else { return nil }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext()
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        
        return UIColor(red: CGFloat(bitmap[0]) / 255.0,
                       green: CGFloat(bitmap[1]) / 255.0,
                       blue: CGFloat(bitmap[2]) / 255.0,
                       alpha: 1.0)
    }


        
    func navigateToRecommendations(with identifier: String, topConfidence: Double) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let recommendationsVC = storyboard.instantiateViewController(withIdentifier: "RecommendationsViewController") as? RecommendationsViewController {
            // Pass the item details to the next view controller
            recommendationsVC.selectedItemIdentifier = identifier
            recommendationsVC.confidenceLevel = topConfidence
            
            // Use present for a modal transition or push for a navigation stack
            if let navigationController = self.navigationController {
                navigationController.pushViewController(recommendationsVC, animated: true)
            } else {
                self.present(recommendationsVC, animated: true, completion: nil)
            }
        } else {
            print("Failed to instantiate RecommendationsViewController.")
            showAlert(title: "Navigation Error", message: "Could not load recommendations page.")
        }
    }


       func showAlert(title: String, message: String) {
           let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
           alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
           self.present(alert, animated: true, completion: nil)
       }
   }
