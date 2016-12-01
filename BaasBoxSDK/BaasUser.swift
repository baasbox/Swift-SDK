/*
 * Copyright (C) 2014. BaasBox
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and limitations under the License.
 */

//
//  BaasUser.swift
//  BB SDK
//
//  Created by Luca Cardelli on 19/11/16.
//  Copyright © 2016 Doppionodo. All rights reserved.
//

import Foundation

/**
 class BaasUser
 
 manages the `BaasBox` logged in user
 
 You can get the user data and manages it from here
 
 */
public class BaasUser: NSObject, NSCoding {
    
    // MARK: Variables
    
    /// Session token from baasbox
    var token: String
    /// User id from baasbox
    var id : String
    /// Username
    var username : String
    /// Status of the user: ACTIVE, SUSPENDED
    var status : String
    /// PushToken, saved here after the push notification are enabled
    var pushToken : String
    /// Bool checking if push notification are enabled
    var pushEnabled : Bool
    /// Bool for checking if is a social login
    var isSocialLogin: Bool
    /// String representing the social login
    var socialType : String
    /// Dictionary of data visible by the user
    var visibleByTheUser : [String: Any]
    /// Dictionary of data visible by friends
    var visibleByFriends : [String: Any]
    /// Dictionary of data visible by anonymous users
    var visibleByAnonymousUsers : [String: Any]
    /// Dictionary of data visible by registered users
    var visibleByRegisteredUsers : [String: Any]
    
    init(auth : String = "", id: String = "", vbtu:[String: Any] = [:], vbf : [String: Any] = [:], vbau : [String: Any] = [:], vbru : [String: Any] = [:], username: String = "", status: String = "", pushToken: String = "", pushEnabled: Bool = false, socialLogin:Bool = false, socialType: String = "") {
        self.token = auth
        self.id = id
        self.visibleByTheUser = vbtu
        self.visibleByFriends = vbf
        self.visibleByAnonymousUsers = vbau
        self.visibleByRegisteredUsers = vbru
        self.username = username
        self.status = status
        self.pushToken = pushToken
        self.pushEnabled = pushEnabled
        self.isSocialLogin = socialLogin
        self.socialType = socialType
    }
    init(withDictionary dict: [String: AnyObject], pushToken: String = "", pushEnabled: Bool = false, socialLogin: Bool = false, socialType: String = "", token: String = "") {
        self.token = token == "" ? dict["X-BB-SESSION"] as! String : token
        self.id = dict["id"] as! String
        self.visibleByTheUser = dict["visibleByTheUser"] as! [String: Any]
        self.visibleByFriends = dict["visibleByFriends"] as! [String: Any]
        self.visibleByAnonymousUsers = dict["visibleByAnonymousUsers"] as! [String: Any]
        self.visibleByRegisteredUsers = dict["visibleByRegisteredUsers"] as! [String: Any]
        let user = dict["user"] as! [String: AnyObject]
        self.username = user["name"] as! String
        self.status = user["status"] as! String
        self.pushToken = pushToken
        self.pushEnabled = pushEnabled
        self.isSocialLogin = socialLogin
        self.socialType = socialType
    }
    /**
     Decodes the saved object
     */
    required convenience public init?(coder aDecoder: NSCoder) {
        let token = aDecoder.decodeObject(forKey: "token") as! String
        let id = aDecoder.decodeObject(forKey: "id") as! String
        let vbtu = aDecoder.decodeObject(forKey: "vbtu") as! [String: Any]
        let vbf = aDecoder.decodeObject(forKey: "vbf") as! [String: Any]
        let vbau = aDecoder.decodeObject(forKey: "vbau") as! [String: Any]
        let vbru = aDecoder.decodeObject(forKey: "vbru") as! [String: Any]
        let username = aDecoder.decodeObject(forKey: "username") as! String
        let status = aDecoder.decodeObject(forKey: "status") as! String
        let pushToken = aDecoder.decodeObject(forKey: "pushtoken") as! String
        let pushEnabled = aDecoder.decodeBool(forKey: "pushenabled")
        let social = aDecoder.decodeBool(forKey: "sociallogin")
        let socialType = aDecoder.decodeObject(forKey: "socialtype") as! String
        self.init(auth: token, id:id, vbtu: vbtu, vbf:vbf, vbau:vbau, vbru:vbru, username:username, status:status, pushToken: pushToken, pushEnabled:pushEnabled, socialLogin:social, socialType:socialType)
    }
    /**
     Encodes the saved object
     */
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(token, forKey: "token")
        aCoder.encode(id, forKey: "id")
        aCoder.encode(visibleByTheUser, forKey: "vbtu")
        aCoder.encode(visibleByFriends, forKey: "vbf")
        aCoder.encode(visibleByAnonymousUsers, forKey: "vbau")
        aCoder.encode(visibleByRegisteredUsers, forKey: "vbru")
        aCoder.encode(username, forKey: "username")
        aCoder.encode(status, forKey: "status")
        aCoder.encode(pushToken, forKey: "pushtoken")
        aCoder.encode(pushEnabled, forKey: "pushenabled")
        aCoder.encode(isSocialLogin, forKey: "sociallogin")
        aCoder.encode(socialType, forKey: "socialtype")
    }
    /**
     Returns a bool if the user is locally authenticated
     
     - return: Boolean for local authentication
     */
    public func isAuthenticated() -> Bool {
        return token != ""
    }
    
    // MARK: User Management
    
    /**
     Upload the saved user updates to the BaasBox server
 
    */
    public func update(completion: BaasBox.BaasCompletion) {
        BaasBox.shared.put(url: "/me", parameters: ["visibleByTheUser" : visibleByTheUser, "visibleByFriends" : visibleByFriends, "visibleByAnonymousUsers": visibleByAnonymousUsers, "visibleByRegisteredUsers" : visibleByRegisteredUsers], completion: { ( success, data, error ) in
            if success {
                BaasBox.saveCurrentUser()
            }
            completion(success, data, error)
        })
    }
    
    /**
     Logout function, will call the function you pass in logoutStrategy on completion
     
     */
    public func logout(pushToken: String = "",completion: BaasBox.BaasCompletion ) {
        let url = pushToken == "" ? "/logout" : "/logout/"+pushToken
        BaasBox.shared.post(url: url, parameters: [:], completion: { ( success, data, error ) in
            BaasBox.getConfig().logoutStrategy.logout()
            completion(success, data, error)
        })
    }
    
    /**
     Refresh the saved data of the user from the server
     
     */
    public func refresh(completion: BaasBox.BaasCompletion ) {
        BaasBox.shared.get(url: "/me", parameters: [:], completion: { ( success, data, error ) in
            if success {
                BaasBox.shared.user = BaasUser.init(withDictionary: data as! [String:AnyObject], pushToken: BaasBox.shared.user.pushToken, pushEnabled:BaasBox.shared.user.pushEnabled, socialLogin: BaasBox.shared.user.isSocialLogin, socialType: BaasBox.shared.user.socialType, token: BaasBox.shared.user.token)
                BaasBox.saveCurrentUser()
            }
            completion(success, data, error )
        })
    }
    /**
     Change the user password.
     
     NOTE:
     =====
     
     Your session code will change
     
     - parameters:
        - from : Old password
        - to : New password
     */
    public func changePassword(from: String, to: String, completion: BaasBox.BaasCompletion) {
        BaasBox.shared.put(url: "/me/password", parameters: ["old": from, "new" : to], completion: {( success, data, error ) in
            if success {
                BaasBox.shared.login(username: BaasBox.shared.user.username, password: to, completion: {(success, data, error) in
                    completion(success, data, error)
                })
            }
            completion(success, data, error )
        })
    }
    
    /**
     Link the user with a social login
     
    - parameters:
        - to: `BaasBox.socialTypes`, the type of the social login
        - token: The token provided by the third party social sdk
     */
    public func link(to: BaasBox.socialTypes, token: String, completion: BaasBox.BaasCompletion) {
        BaasBox.shared.put(url: "/social/"+to.rawValue, parameters: ["oauth_token": token, "oauth_secret": token], completion: { (success, data, error) in
            completion(success,data,error)
        })
    }
    
    // MARK: Follow
    
    
    /**
     Follows a user
     
     - parameters:
        -username: The username of the user to follow
     */
    public func follow(username: String, completion: BaasBox.BaasCompletion) {
        BaasBox.shared.post(url: "/follow/"+username, parameters: [:], completion: { (success, data, error) in
            completion(success,data,error)
        })
    }
    
    /**
     Unfollows a user
     
     - parameters:
     -username: The username of the user to unfollow
     */
    public func unfollow(username: String, completion: BaasBox.BaasCompletion) {
        BaasBox.shared.delete(url: "/follow/"+username, parameters: [:], completion: { (success, data, error) in
            completion(success,data,error)
        })
    }
    
    /**
     Get the user follows

     */
    public func getFollows(completion: BaasBox.BaasCompletion) {
        BaasBox.shared.get(url: "/following/"+self.username, parameters: [:], completion: { (success, data, error) in
            completion(success, data, error)
        })
    }
    
    /**
     Get the user followers
     
     */
    public func getFollowers(completion: BaasBox.BaasCompletion) {
        BaasBox.shared.get(url: "/followers/"+self.username, parameters: [:], completion: { (success, data, error) in
            completion(success, data, error)
        })
    }
}
