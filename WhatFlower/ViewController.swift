//
//  ViewController.swift
//  WhatFlower
//
//  Created by Iurii Plugatarov on 19/06/2018.
//  Copyright © 2018 Iurii Plugatarov. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  let imagePicker = UIImagePickerController()
  let wikipediaURl = "https://en.wikipedia.org/w/api.php"
  
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var descriptionLabel: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    imagePicker.delegate = self
    imagePicker.allowsEditing = false
    imagePicker.sourceType = .camera
  }
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
    
    guard let visionImage = CIImage(image: userPickedImage!) else { fatalError("Cannot convert image") }
    
    detect(image: visionImage)
    
    imageView.image = userPickedImage
    imagePicker.dismiss(animated: true, completion: nil)
  }


  @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
    present(imagePicker, animated: true, completion: nil)
  }
  
  func detect(image: CIImage) {
    guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {fatalError("Could not import model")}
    
    let request = VNCoreMLRequest(model: model) { request, error in
      guard let classification = request.results?.first as? VNClassificationObservation else {
        fatalError("Classification error")
      }
      
      self.navigationItem.title = classification.identifier.capitalized
      self.requestInfo(flowerName: classification.identifier)
    }
    let handler = VNImageRequestHandler(ciImage: image)
    
    do {
      try handler.perform([request])
    } catch {
      print("could not process mlmodel")
    }
  }
  
  func requestInfo(flowerName: String) {
    let parameters : [String:String] = [
      "format" : "json",
      "action" : "query",
      "prop" : "extracts|pageimages",
      "exintro" : "",
      "explaintext" : "",
      "titles" : flowerName,
      "indexpageids" : "",
      "redirects" : "1",
      "pithumbsize" : "500"
    ]
    
    Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON() { response in
      if response.result.isSuccess {
        print("Got Wikipedia Info")
        let flowerJSON : JSON = JSON(response.result.value!)
        let pageId = flowerJSON["query"]["pageids"][0].stringValue
        let flowerDescription = flowerJSON["query"]["pages"][pageId]["extract"].stringValue
        let flowerImageUrl = flowerJSON["query"]["pages"][pageId]["thumbnail"]["source"].stringValue
        
        self.imageView.sd_setImage(with: URL(string: flowerImageUrl))
        
        self.descriptionLabel.text = flowerDescription
      }
    }
  }
}

