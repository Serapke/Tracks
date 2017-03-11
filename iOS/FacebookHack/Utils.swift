//
//  Data.swift
//  FacebookHack
//
//  Created by Jay Lees on 11/03/2017.
//  Copyright © 2017 Jay Lees. All rights reserved.
//

import Foundation

func triggerGETRequestWith(reqUrl: String, authToken: String, viewController: UIViewController){
    var request = URLRequest(url: URL(string: reqUrl)!)
    request.httpMethod = "GET"
    print("Sending \(authToken)")
    request.setValue(authToken, forHTTPHeaderField: "Authorization")
    

    let session = URLSession.shared
    
    let task = session.dataTask(with: request as URLRequest) { (data, response, error) -> Void in
        // Check for fundamental networking error
        guard let data = data, error == nil else {
            print("error=\(error)")
            return
        }
        
        // Check for HTTP errors
        if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
            print("statusCode should be 200, but is \(httpStatus.statusCode)")
            print("Response = \(response)")
            
            let responseString = String(data: data, encoding: .utf8)?.replacingOccurrences(of: "\\", with: "", options: .literal, range: nil)
            print("response (bad response) = \(responseString!))")
            
            let responseArr: [String: Any] = dataToJSON(data: data) as! [String: Any]
            print(responseArr["errorCode"] as! Int)
            
            displayAlertViewWith(title: "Error Occured", message: "Error Occured", viewController: viewController)
            return
        }
        
       // let responseString = String(data: data, encoding: .utf8)
            //.replacingOccurrences(of: "\\", with: "", options: .literal, range: nil)
        extractSong(responseData: data)
        
//        if responseString == "true"{
//            print("Loading main screen")
//            NotificationCenter.default.post(name:Notification.Name(rawValue:"successfulLogin"), object: nil, userInfo: nil)
//        }
    }
    task.resume()
}

func triggerPOSTRequestWith(reqUrl: String, params: String, viewController: UIViewController){
    var request = URLRequest(url: URL(string: reqUrl)!)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    
    request.httpBody = params.data(using: .utf8)
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        // Check for fundamental networking error
        guard let data = data, error == nil else {
            print("error=\(error)")
            return
        }
        
        // Check for HTTP errors
        if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
            print("statusCode should be 200, but is \(httpStatus.statusCode)")
            print("Response = \(response)")
            
            let responseString = String(data: data, encoding: .utf8)?.replacingOccurrences(of: "\\", with: "", options: .literal, range: nil)
            print("response (bad response) = \(responseString!))")
            
            let responseArr: [String: Any] =
                dataToJSON(data: data) as! [String: Any]
            print(responseArr["errorCode"] as! Int)
            
            displayAlertViewWith(title: "Error Occured", message: "Error Occured", viewController: viewController)
            return
        }
        
        let responseString = String(data: data, encoding: .utf8)?.replacingOccurrences(of: "\\", with: "", options: .literal, range: nil)
//        print("response (good response) = \(responseString!)")
        
        // We know we have a successful login at this point so can extract the auth token
        extractAndStoreAuthToken(responseData: data)
    
        NotificationCenter.default.post(name: NSNotification.Name.init("successfulLogin"), object: nil)
    }
    task.resume()
}


func displayAlertViewWith(title: String, message: String, viewController: UIViewController){
    DispatchQueue.main.async {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
        viewController.present(alert, animated: true, completion: nil)
        alert.addAction(okAction)
    }
}

//MARK: JSON Parser
func dataToJSON(data: Data) -> Any? {
    do {
        let JSON = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
        return JSON
    } catch let error as NSError {
        print("Error whilst trying to parse JSON: \(error.userInfo)")
    }
    return nil
}

func extractAndStoreAuthToken(responseData: Data){
    let responseArr: [String : Any] = dataToJSON(data: responseData) as! [String : Any]
    print("Auth Token: \(responseArr["auth_token"]!)")
    UserDefaults.standard.set(responseArr["auth_token"]!, forKey: "authToken")
}

func extractSong(responseData: Data){
    let responseArr: [String : Any] = dataToJSON(data: responseData) as! [String : Any]
    if responseArr["spotify_id"] as! String != UserDefaults.standard.string(forKey: "spotify_id")! {
        UserDefaults.standard.set(responseArr["spotify_id"]!, forKey: "spotify_id")
        NotificationCenter.default.post(name: NSNotification.Name.init("successfulNewSong"), object: nil)
    }
}
