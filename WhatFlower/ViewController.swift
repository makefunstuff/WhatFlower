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

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  let imagePicker = UIImagePickerController()
  @IBOutlet weak var imageView: UIImageView!
  
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
      let classification = request.results?.first as? VNClassificationObservation
      
      self.navigationItem.title = classification?.identifier.capitalized
    }
    let handler = VNImageRequestHandler(ciImage: image)
    
    do {
      try handler.perform([request])
    } catch {
      print("could not process mlmodel")
    }
  }
}

