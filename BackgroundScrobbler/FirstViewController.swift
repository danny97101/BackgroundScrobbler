//
//  FirstViewController.swift
//  BackgroundScrobbler
//
//  Created by Daniel Akimchuk on 8/20/18.
//  Copyright © 2018 okdanny. All rights reserved.
//

import UIKit
import Foundation
import Alamofire




class FirstViewController: UIViewController {
    @IBOutlet weak var userNameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let defaults = UserDefaults.standard
        //defaults.removeObject(forKey: "last.fm username")
        //defaults.removeObject(forKey: "last.fm password")
        //defaults.synchronize()

        if let _ = defaults.string(forKey: "last.fm username") {
            if let _ = defaults.string(forKey: "last.fm password") {
                loadNextView()
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func loginPressed(_ sender: Any) {
        let username = userNameField.text!
        let password = passwordField.text!
        let defaults = UserDefaults.standard
        defaults.set(username, forKey: "last.fm username")
        defaults.set(password, forKey: "last.fm password")
        if let _ = defaults.string(forKey: "last.fm username") {
            if let _ = defaults.string(forKey: "last.fm password") {
                
                NotificationCenter.default.addObserver(self, selector: #selector(loadNextView), name: Notification.Name(rawValue: "loginSuccessful"), object: nil)
                //let lastfmUrl = URL(string: "https://ws.audioscrobbler.com/2.0/?method=auth.getMobileSession&format=json")
                //var lfmRequest = URLRequest(url: lastfmUrl!)
                //lfmRequest.httpMethod = "POST"
                let sig = md5("api_key30de5967bb20f2e96bd7a7514a6205acmethodauth.getMobileSessionpassword" + password + "username" + username + "4611dc9dbbfe3f7cb20e0cc8c5ca65c1")
                
                
                let parameters: [String: Any] = [
                    "username": username,
                    "password": password,
                    "api_key": "30de5967bb20f2e96bd7a7514a6205ac",
                    "api_sig": sig,
                    "method": "auth.getMobileSession",
                    "format": "json"
                ]
                
                
                Alamofire.request("https://ws.audioscrobbler.com/2.0/", method: HTTPMethod.post, parameters: parameters, encoding: URLEncoding.default).responseJSON { response in
                        if let data = response.data {
                            do {
                                var jsonSerialized = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
                                jsonSerialized = jsonSerialized!["session"] as! [String : Any?] as [String : Any]
                                if let key = jsonSerialized?["key"] as? String {
                                    defaults.set(key, forKey: "last.fm key")
                                }
                                print(defaults.string(forKey: "last.fm key"))
                            } catch _ as NSError {
                            }
                        }
                    }
                
                loadNextView()
            }
        }
    }
    
    @objc func loadNextView() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "TabBarController") as! UITabBarController
        self.present(newViewController, animated: true, completion: nil)
    }
    
    
    @objc func md5(_ string: String) -> String {
        
        let context = UnsafeMutablePointer<CC_MD5_CTX>.allocate(capacity: 1)
        var digest = Array<UInt8>(repeating:0, count:Int(CC_MD5_DIGEST_LENGTH))
        CC_MD5_Init(context)
        CC_MD5_Update(context, string, CC_LONG(string.lengthOfBytes(using: String.Encoding.utf8)))
        CC_MD5_Final(&digest, context)
        context.deallocate()
        var hexString = ""
        for byte in digest {
            hexString += String(format:"%02x", byte)
        }
        
        return hexString
    }
    
}

