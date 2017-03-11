//
//  ViewController.swift
//  FacebookHack
//
//  Created by Jay Lees on 11/03/2017.
//  Copyright © 2017 Jay Lees. All rights reserved.
//

import UIKit
import FacebookLogin

class ViewController: UIViewController, SPTAudioStreamingDelegate {
    
    var firstLoad: Bool!
    var spotifyValidated = false
    var facebookValidated = false
    
    @IBOutlet weak var spotifyLoginButton: UIButton!
    @IBOutlet weak var getStartedButton: UIButton!
    
    override func viewDidLoad(){
        super.viewDidLoad()
        UserDefaults.standard.setValue("00", forKey: "spotify_id")
        firstLoad = true
        setupButtons()
        let loginButton = LoginButton(readPermissions: [.publicProfile])
        loginButton.center = view.center
        view.addSubview(loginButton)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(true)
         NotificationCenter.default.addObserver(self, selector: #selector(self.spotifySessionUpdatedNotification), name: NSNotification.Name(rawValue: "spotifySessionUpdated"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.facebookSessionUpdatedNotification), name: NSNotification.Name(rawValue: "facebookSessionUpdated"), object: nil)
        let auth = SPTAuth.defaultInstance()
        if (FBSDKAccessToken.current() != nil) {
            facebookValidated = true
            checkIfBothValid()
        }
        if auth?.session == nil {
            return
        }
        if auth!.session.isValid() && self.firstLoad {
            spotifyValidated = true
            spotifyLoginButton.isEnabled = false
            spotifyLoginButton.alpha = 0.5
            checkIfBothValid()
            return
        }
        if auth!.hasTokenRefreshService {
            renewTokenAndShowPlayer()
            return
        }
        
    }
    
    func setupButtons(){
        getStartedButton.isEnabled = false
        getStartedButton.alpha = 0.5
        getStartedButton.layer.shadowColor = UIColor.black.cgColor
        getStartedButton.layer.shadowOffset = CGSize(width: 3, height: 3)
        getStartedButton.layer.shadowOpacity = 0.7
        getStartedButton.layer.shadowRadius = 4.0
        getStartedButton.layer.cornerRadius = 6
        spotifyLoginButton.layer.shadowColor = UIColor.black.cgColor
        spotifyLoginButton.layer.shadowOffset = CGSize(width: 3, height: 3)
        spotifyLoginButton.layer.shadowOpacity = 0.6
        spotifyLoginButton.layer.shadowRadius = 4.0
        spotifyLoginButton.layer.cornerRadius = 6

    }
    
    func spotifySessionUpdatedNotification(_ notification: Notification) {
        let auth = SPTAuth.defaultInstance()
        if auth!.session != nil && auth!.session.isValid() {
            spotifyValidated = true
            spotifyLoginButton.isEnabled = false
            checkIfBothValid()
        } else {
            print("*** Failed to log in")
        }
    }
    
    func facebookSessionUpdatedNotification(_ notification: Notification) {
        if FBSDKAccessToken.current() != nil {
            facebookValidated = true
            checkIfBothValid()
        }
    }
    
    func checkIfBothValid(){
        if facebookValidated && spotifyValidated {
            getStartedButton.isEnabled = true
            getStartedButton.alpha = 1
            
            let email = "test@test.com"
            let password = "123456"
            
            
            let paramString = "{\"session\": {\"email\": \"\(email)\", \"password\": \"\(password)\"}}"
            
            triggerPOSTRequestWith(reqUrl: "https://tracks-api.herokuapp.com/sessions", params: paramString, viewController: self)
            showPlayer()
        }
    }
    
    func showPlayer() {
        self.firstLoad = false
        performSegue(withIdentifier: "showPlayerView", sender: self)
    }
    
    func renewTokenAndShowPlayer() {
        print("Refreshing token...")
        SPTAuth.defaultInstance().renewSession(SPTAuth.defaultInstance().session) { error, session in
            SPTAuth.defaultInstance().session = session
            if error != nil {
                print("*** Error renewing session: \(error)")
                return
            }
            self.spotifyValidated = true
            self.spotifyLoginButton.isEnabled = false
            self.checkIfBothValid()
        }
    }
    
    @IBAction func loginWithSpotifyTapped(_ sender: Any) {
        let URLAuth = SPTAuth.defaultInstance().spotifyWebAuthenticationURL()
        UIApplication.shared.open(URLAuth!, options: [:], completionHandler: nil)
        
    }
    
    @IBAction func getStartedButtonTapped(_ sender: Any) {
        showPlayer()
    }

}

