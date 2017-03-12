//
//  PlayerViewController.swift
//  FacebookHack
//
//  Created by Jay Lees on 11/03/2017.
//  Copyright © 2017 Jay Lees. All rights reserved.
//

import UIKit
import AudioToolbox
import AVFoundation
import CoreLocation

class PlayerViewController: UIViewController, SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UIGestureRecognizerDelegate {

    var isChangingProgress: Bool = false
    var userLat = 0.0
    var userLong = 0.0
    let locationManager = CLLocationManager()
    let audioSession = AVAudioSession.sharedInstance()
    let pickerDataWords = ["5 seconds", "10 seconds", "30 seconds", "1 minute", "5 minutes"]
    let pickerDataSeconds = [5, 10, 30, 60, 300]
    var timeDelay = 5
    
    @IBOutlet weak var albumArtworkView: UIImageView!
    @IBOutlet weak var largeArtworkView: UIImageView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var trackNameText: UILabel!
    @IBOutlet weak var albumArtistText: UILabel!
    @IBOutlet weak var userLocationText: UILabel!
    @IBOutlet weak var refreshTimePicker: UIPickerView!
    @IBOutlet weak var pickerViewToTop: NSLayoutConstraint!
    @IBOutlet weak var pickerViewSize: NSLayoutConstraint!
    @IBOutlet weak var pickerViewShadow: UIView!
    
    var canGetData = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(self.loginSuccess), name: NSNotification.Name(rawValue: "successfulLogin"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.changeSong), name: NSNotification.Name(rawValue: "successfulNewSong"), object: nil)
        if let existingTimeDelay = UserDefaults.standard.value(forKey: "timeDelay") {
            timeDelay = existingTimeDelay as! Int
        }
        setupView()
        handleNewSession()
        getUsersLocation()
        self.refreshTimePicker.delegate = self
        self.refreshTimePicker.dataSource = self
        Timer.scheduledTimer(timeInterval: Double(timeDelay), target: self, selector: #selector(self.getUsersLocation), userInfo: nil, repeats: true)
    }
    
    func setupView(){
        pickerViewShadow.layer.shadowColor = UIColor.black.cgColor
        pickerViewShadow.layer.shadowOffset = CGSize(width: 0, height: -3)
        pickerViewShadow.layer.shadowOpacity = 0.5
        pickerViewShadow.layer.shadowRadius = 4.0
        albumArtworkView.layer.shadowColor = UIColor.black.cgColor
        albumArtworkView.layer.shadowOffset = CGSize(width: 3, height: 3)
        albumArtworkView.layer.shadowOpacity = 0.7
        albumArtworkView.layer.shadowRadius = 4.0
        pickerViewToTop.constant = 746
    }
    
    func loginSuccess(){
        canGetData = true
    }
    
    //MARK: - SPOTIFY SESSION
    func handleNewSession() {
        do {
            try SPTAudioStreamingController.sharedInstance().start(withClientId: SPTAuth.defaultInstance().clientID, audioController: nil, allowCaching: true)
            SPTAudioStreamingController.sharedInstance().delegate = self
            SPTAudioStreamingController.sharedInstance().playbackDelegate = self
            SPTAudioStreamingController.sharedInstance().diskCache = SPTDiskCache()
            SPTAudioStreamingController.sharedInstance().login(withAccessToken: SPTAuth.defaultInstance().session.accessToken!)
        } catch let error {
            print("Error whilst trying to log in handle new session: \(error.localizedDescription)")
            self.closeSession()
        }
    }
    
    func closeSession() {
        do {
            try SPTAudioStreamingController.sharedInstance().stop()
            SPTAuth.defaultInstance().session = nil
            _ = self.navigationController!.popViewController(animated: true)
        } catch let error {
            print("Error whilst trying to log out \(error)")
        }
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController, didReceiveMessage message: String) {
        let alert = UIAlertController(title: "Message from Spotify", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: { _ in })
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController, didChangePlaybackStatus isPlaying: Bool) {
        if isPlaying {
            self.activateAudioSession()
            playPauseButton.imageView?.image = UIImage(named: "Pause")
        }
        else {
            self.deactivateAudioSession()
            playPauseButton.imageView?.image = UIImage(named: "Play")
        }
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController, didChange metadata: SPTPlaybackMetadata) {
        updateUserInterface()
    }
    
    func audioStreamingDidLogout(_ audioStreaming: SPTAudioStreamingController) {
        self.closeSession()
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController, didReceiveError error: Error?) {
        print("Recieved error: \(error!.localizedDescription)")
    }
    
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController) {
        updateUserInterface()
        playSong(withURI: "spotify:user:jay_lees:playlist:06EIF3a0hPaXaVlZQKl5eT")
    }
    
    func playSong(withURI: String){
        SPTAudioStreamingController.sharedInstance().playSpotifyURI(withURI, startingWith: 0, startingWithPosition: 0) { error in
            if error != nil {
                print("*** failed to play: \(error)")
                return
            }
        }
    }
    
    func activateAudioSession() {
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
            try audioSession.setActive(true)
            
        }
        catch let error {
            print(error.localizedDescription)
        }
    }
    
    func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        }
        catch let error {
            print(error.localizedDescription)
        }
    }
    
    func updateUserInterface(){
        let auth = SPTAuth.defaultInstance()
        if SPTAudioStreamingController.sharedInstance().metadata == nil || SPTAudioStreamingController.sharedInstance().metadata.currentTrack == nil {
            self.albumArtworkView.image = nil
            return
        }
        SPTTrack.track(withURI: URL(string: SPTAudioStreamingController.sharedInstance().metadata.currentTrack!.uri)!, accessToken: auth!.session.accessToken, market: nil) { error, result in
            self.trackNameText.text = SPTAudioStreamingController.sharedInstance().metadata.currentTrack?.name
            self.albumArtistText.text = ((SPTAudioStreamingController.sharedInstance().metadata.currentTrack?.artistName)! + " - " + (SPTAudioStreamingController.sharedInstance().metadata.currentTrack?.albumName)!)

            if let track = result as? SPTTrack {
                let imageURL = track.album.largestCover.imageURL
                if imageURL == nil {
                    print("Album \(track.album) doesn't have any images!")
                    self.albumArtworkView.image = nil
                    return
                }
                DispatchQueue.global().async {
                    do {
                        let imageData = try Data(contentsOf: imageURL!, options: [])
                        let image = UIImage(data: imageData)
                        DispatchQueue.main.async {
                            self.albumArtworkView.image = image
                            let blurred = self.applyBlur(on: image!, withRadius: 10.0)
                            self.largeArtworkView.image = blurred
                            if image == nil {
                                print("Couldn't load cover image with error: \(error)")
                                return
                            }
                        }
                    } catch let error {
                        print(error.localizedDescription)
                    }
                }
            }
        }

    }
    
    
    //MARK: - Image Blurring
    func applyBlur(on imageToBlur: UIImage, withRadius blurRadius: CGFloat) -> UIImage {
        let originalImage = CIImage(cgImage: imageToBlur.cgImage!)
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(originalImage, forKey: "inputImage")
        filter?.setValue(blurRadius, forKey: "inputRadius")
        let outputImage = filter?.outputImage
        let context = CIContext(options: nil)
        let outImage = context.createCGImage(outputImage!, from: outputImage!.extent)
        let ret = UIImage(cgImage: outImage!)
        return ret
    }
    
    //MARK: - Button Methods
    @IBAction func playPauseTouched(_ sender: Any) {
        SPTAudioStreamingController.sharedInstance().setIsPlaying(!SPTAudioStreamingController.sharedInstance().playbackState.isPlaying, callback: nil)
    }
    
    @IBAction func timerButtonTapped(_ sender: Any) {
        if pickerViewToTop.constant == 746{
            UIView.animate(withDuration: 0.5, animations: {
                self.pickerViewToTop.constant = 446
                self.view.layoutIfNeeded()
            })
        } else {
            UIView.animate(withDuration: 0.5, animations: {
                self.pickerViewToTop.constant = 746
                self.view.layoutIfNeeded()
            })
            UserDefaults.standard.set(timeDelay, forKey: "timeDelay")
        }
    }
    
    //MARK: - Location Methods
    func getUsersLocation(){
        locationManager.requestAlwaysAuthorization()
        if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways {
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            let locValue:CLLocationCoordinate2D = locationManager.location!.coordinate
            userLat = locValue.latitude
            userLong = locValue.longitude
            checkSongForLocation()
            let geocoder = CLGeocoder()
            let location = CLLocation(latitude: userLat, longitude: userLong)
            
            geocoder.reverseGeocodeLocation(location, completionHandler: { placemarks in
                let array = placemarks.0
                if let placemark = array?[0] {
                    if placemark.subLocality != nil {
                        if placemark.administrativeArea != nil {
                            self.userLocationText.text = "Your location: \(placemark.subLocality!), \(placemark.subAdministrativeArea!)"
                        } else {
                            self.userLocationText.text = "Your location: \(placemark.subLocality!)"
                        }
                    }
                }
            })
        } else if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.denied {
            let alert = UIAlertController(title: "Location Services Disabled", message: "Please enable location services for this app in Settings.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            present(alert, animated: true, completion: nil)
            alert.addAction(okAction)
        }
    }
    
    
    //MARK - Picker View Methods
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerDataWords.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerDataWords[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        timeDelay = pickerDataSeconds[row]
    }
    
    //MARK: - Change song methods
    func checkSongForLocation(){
        if let authTok = UserDefaults.standard.string(forKey: "authToken") {
            if canGetData {
                triggerGETRequestWith(reqUrl: "https://tracks-api.herokuapp.com/get_song?location=[\(userLat),\(userLong)]", authToken: authTok, viewController: self)
            }
        }
    }
    
    func changeSong(){
        let songID = UserDefaults.standard.value(forKey: "spotify_id") as! String
        playSong(withURI: "spotify:track:\(songID)")
    }
    
    //MARK: - Gesture Recogniser
    @IBAction func userDidTapView(_ sender: Any) {
        UIView.animate(withDuration: 0.5, animations: {
            self.pickerViewToTop.constant = 746
            self.view.layoutIfNeeded()
        })
        UserDefaults.standard.set(timeDelay, forKey: "timeDelay")
    }
    
}
