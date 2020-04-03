//
//  RoomDetailsViewController.swift
//  Dante Patient
//
//  Created by Xinhao Liang on 9/15/19.
//  Copyright © 2019 Xinhao Liang. All rights reserved.
//

import UIKit
import SceneKit
import FirebaseStorage

class RoomDetailsViewController: UIViewController {
    
    @IBOutlet weak var navigationVIew: UIView!
    @IBOutlet weak var navHeight: NSLayoutConstraint!
    
    
    @IBOutlet weak var sceneView: SCNView!
    var scene: SCNScene!
    
    // received string from the map
    var roomStr: String!
    
    var filename = "sample3D-1.scn"
    var textureFilename = "sample3D-1.jpg"
    var textureImage: UIImage!
    
    // storage reference
    var imageReference = Storage.storage().reference().child("images")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let height = UIScreen.main.bounds.height
        if height >= 812 {
            self.navHeight.constant = 88
        } else {
            self.navHeight.constant = 64
        }
        
        // set up Scene
        sceneView.allowsCameraControl = true
    }
    
    override func viewWillAppear(_ animated: Bool) {

        self.loadTexture { () -> () in
            self.loadImage()
        }
        
    }
    
    func loadTexture(handleComplete: @escaping ()->()) {
        let downloadImageTextureRef = imageReference.child(textureFilename)

        downloadImageTextureRef.downloadURL(completion: { url, error in
            if let imgLink = url {
                do {
                    let data = try Data(contentsOf: imgLink)
                    self.textureImage = UIImage(data: data)
                } catch {
                    print(error)
                }
            }
            handleComplete()
        })
    }
    
    func loadImage() {
        let downloadImageRef = imageReference.child(filename)

        downloadImageRef.downloadURL(completion: { url, error in
            if let imgLink = url {
                do {
                    self.scene = try SCNScene(url: imgLink, options: nil)
                    self.scene.background.contents = UIColor.black
                    if let node = self.scene.rootNode.childNode(withName: "MDL_OBJ_material_0", recursively: true) {
                        let material = SCNMaterial()
                        material.diffuse.contents = self.textureImage
                        node.geometry?.materials = [material]
                    }
                    self.sceneView.scene = self.scene
                }
                catch {
                    print("cannot render 3D image")
                }
            }
            else {
                print(error ?? "NO ERROR")
            }
        })
    }

    @IBAction func onCancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
