//
//  ViewController.swift
//  FacebookHack
//
//  Created by Jay Lees on 11/03/2017.
//  Copyright © 2017 Jay Lees. All rights reserved.
//

import UIKit
import FacebookLogin
import FacebookCore

struct MyProfileRequest: GraphRequestProtocol {
    struct Response: GraphResponseProtocol {
        init(rawResponse: Any?) {
            // Decode JSON from rawResponse into other properties here.
        }
    }
    
    var graphPath = "/me/friends"
    var parameters: [String : Any]? = ["fields": "id, name"]
    var accessToken = AccessToken.current
    var httpMethod: GraphRequestHTTPMethod = .GET
    var apiVersion: GraphAPIVersion = .defaultVersion
}

class ViewController: UIViewController, SPTAudioStreamingDelegate {
    
    var firstLoad: Bool!
    var spotifyValidated = false
    var facebookValidated = false
    
    @IBOutlet weak var spotifyLoginButton: UIButton!
    @IBOutlet weak var facebookLoginButton: UIButton!
    @IBOutlet weak var getStartedButton: UIButton!
    
    //MARK: - Override Methods
    override func viewDidLoad(){
        super.viewDidLoad()
        UserDefaults.standard.setValue("00", forKey: "spotify_id")
        firstLoad = true

    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent 
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(true)
                setupButtons()
         NotificationCenter.default.addObserver(self, selector: #selector(self.spotifySessionUpdatedNotification), name: NSNotification.Name(rawValue: "spotifySessionUpdated"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.facebookSessionUpdatedNotification), name: NSNotification.Name(rawValue: "facebookSessionUpdated"), object: nil)
        let auth = SPTAuth.defaultInstance()
        if (FBSDKAccessToken.current() != nil) {
            facebookValidated = true
            let connection = GraphRequestConnection()
            connection.add(GraphRequest(graphPath: "/me/friends")) { httpResponse, result in
                switch result {
                case .success(let response):
                    print("Graph Request Succeeded: \(response)")
                case .failed(let error):
                    print("Graph Request Failed: \(error)")
                }
            }
            connection.start()
            checkIfBothValid()
        }
        
        if auth!.hasTokenRefreshService {
            renewTokenAndShowPlayer()
            return
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
        
    }
    
    //MARK: - View Update
    func setupButtons(){
        print("Setting up")
        getStartedButton.isEnabled = false
        getStartedButton.alpha = 0.5
        if !spotifyValidated{
            spotifyLoginButton.backgroundColor = UIColor(red: 101/255, green: 212/255, blue: 110/255, alpha: 1)
            spotifyLoginButton.isEnabled = true
            spotifyLoginButton.alpha = 1
        }
        
        if !facebookValidated {
            facebookLoginButton.backgroundColor = UIColor(red: 40/255, green: 89/255, blue: 156/255, alpha: 1)
            facebookLoginButton.isEnabled = true
            facebookLoginButton.alpha = 1

        }
        
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
        facebookLoginButton.layer.shadowColor = UIColor.black.cgColor
        facebookLoginButton.layer.shadowOffset = CGSize(width: 3, height: 3)
        facebookLoginButton.layer.shadowOpacity = 0.6
        facebookLoginButton.layer.shadowRadius = 4.0
        facebookLoginButton.layer.cornerRadius = 6

    }

    func showPlayer() {
        self.firstLoad = false
        let transition: CATransition = CATransition()
        transition.duration = 1
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        transition.type = kCATransitionFade
        self.navigationController!.view.layer.add(transition, forKey: nil)
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "playerView") as! PlayerViewController
        self.navigationController?.pushViewController(vc, animated: false)
    }
    
    func renewTokenAndShowPlayer() {
        print("Refreshing token")
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
    
    //MARK: Session update from authentication
    func spotifySessionUpdatedNotification(_ notification: Notification) {
        spotifyLoginButton.backgroundColor = UIColor.gray
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
        facebookValidated = true
        facebookLoginButton.backgroundColor = UIColor.gray
        checkIfBothValid()
    }
    
    func checkIfBothValid(){
        if facebookValidated && spotifyValidated {
            getStartedButton.isEnabled = true
            getStartedButton.alpha = 1
            
            let email = "test@test.com"
            let password = "123456"
            
            
            let paramString = "{\"session\": {\"email\": \"\(email)\", \"password\": \"\(password)\"}}"
            
            //triggerPOSTRequestWith(reqUrl: "https://tracks-api.herokuapp.com/sessions", params: paramString, viewController: self)
            showPlayer()
        }
    }
    
    //MARK: - Button Methods
    @IBAction func loginWithSpotifyTapped(_ sender: Any) {
        let URLAuth = SPTAuth.defaultInstance().spotifyWebAuthenticationURL()
        UIApplication.shared.open(URLAuth!, options: [:], completionHandler: nil)
    }
    
    
    @IBAction func loginWithFacebookTapped(_ sender: Any) {
        let loginManager = LoginManager()
        loginManager.logIn([.publicProfile, .userFriends], viewController: self) { loginResult in
            switch loginResult {
            case .failed(let error):
                print(error)
            case .cancelled:
                print("User cancelled login.")
            case .success(_, _, _):
                print("login was success")
            }
        }
    }
    
    @IBAction func getStartedButtonTapped(_ sender: Any) {
        showPlayer()
    }

}

