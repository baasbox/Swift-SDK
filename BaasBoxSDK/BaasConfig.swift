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
//  BaasConfig.swift
//  BB SDK
//
//  Created by Luca Cardelli on 23/11/16.
//  Copyright © 2016 Doppionodo. All rights reserved.
//

import Foundation
/**
 BaasConfig class, let you declare your `BaasBox` Configs before setup
 
 BaasConfig Object:
 ==================
 - timeout: Double
 - retrylogin: Boolean that indicates if the SDK should save the user password encrypted and use it when server returns 401
 - loginStrategy: A login strategy see `BaasLoginStrategy` ( user defined functions for login ), if empty the default one will be used
 - signupStrategy: A signup strategy see `BaasSignupStrategy` ( user defined functions for signup ), if empty the default one will be used
 - logoutStrategy: A logout strategy see `BaasLogoutStrategy` ( user defined functions for logout: called on logout or on user not authorized ), if empty the default one will be used
 
 */
public class BaasConfig {
    
    var timeout : TimeInterval
    var retrylogin : Bool
    var loginStrategy : BaasLoginStrategy
    var signupStrategy : BaasSignupStrategy
    var logoutStrategy : BaasLogoutStrategy
    
    init(timeout:Double = 10.0, retrylogin:Bool = true, loginStrategy: BaasLoginStrategy = BaasDefaultLoginStrategy(), signupStrategy: BaasSignupStrategy = BaasDefaultSignupStrategy(), logoutStrategy: BaasLogoutStrategy = BaasDefaultLogoutStrategy()) {
        self.timeout = timeout
        self.retrylogin = retrylogin
        self.loginStrategy = loginStrategy
        self.signupStrategy = signupStrategy
        self.logoutStrategy = logoutStrategy
    }
}

/**
 Protocol BaasLoginStrategy
 
 you should extend this protocol for your custom login strategy
 */
public protocol BaasLoginStrategy {
    /// override for login, you can use the default one like this
    ///     BaasDefaultLoginStrategy().login(...)
    func login(username: String, password: String, completion: BaasBox.BaasCompletion)
    /// override for social login, you can use the default one like this
    ///     BaasDefaultLoginStrategy().socialLogin(...)
    func socialLogin(to: BaasBox.socialTypes, token: String, completion: BaasBox.BaasCompletion)
}

/**
 Protocol BaasSignupStrategy
 
 you should extend this protocol for your custom signup strategy
 */
public protocol BaasSignupStrategy {
    /// override for signup, you can use the default one like this
    ///     BaasDefaultSignupStrategy().signup(...)
    func signup(username: String, password: String, visibleByTheUser : [String: Any], visibleByFriends : [String: Any], visibleByRegisteredUsers : [String: Any], visibleByAnonymousUsers : [String: Any], completion: BaasBox.BaasCompletion)
}
/**
 Protocol BaasLogoutStrategy
 
 you should extend this protocol for your custom logout strategy
 */
public protocol BaasLogoutStrategy {
    /// Function called when the user is not authorized
    /// usually you should logout the user here
    func notAuthorized()
    /// Function called onlogout
    /// usually you invalidate personal user settings
    func logout()
}
class BaasDefaultLoginStrategy: BaasLoginStrategy {
    func login(username: String, password: String, completion: BaasBox.BaasCompletion) {
        assert(username != "" && password != "", "Username or password for user login cannot be empty")
        BaasBox.shared.post(url: "/login", parameters: ["username": username, "password":password, "appcode": BaasBox.getAppcode()!], completion: { (success, data, error) in
            if success {
                print(data!)
                if BaasBox.getConfig().retrylogin { BaasBox.saveUserPass(pass: password) }
                BaasBox.shared.user = BaasUser.init(withDictionary: data as! [String:AnyObject], pushToken: BaasBox.shared.user.pushToken, pushEnabled:BaasBox.shared.user.pushEnabled)
                BaasBox.saveCurrentUser()
            }
            completion(success, data, error)
        })
    }
    func socialLogin(to: BaasBox.socialTypes, token: String, completion: BaasBox.BaasCompletion) {
        assert(token != "", "Token for social login cannot be empty")
        BaasBox.shared.post(url: "/social/"+to.rawValue, parameters: ["oauth_token": token, "oauth_secret": token], completion: { (success, data, error) in
            if success {
                if BaasBox.getConfig().retrylogin { BaasBox.saveUserPass(pass: token) }
                BaasBox.shared.user = BaasUser.init(withDictionary: data as! [String:AnyObject], pushToken: BaasBox.shared.user.pushToken, pushEnabled:BaasBox.shared.user.pushEnabled, socialLogin:true, socialType: to.rawValue)
                BaasBox.saveCurrentUser()
            }
            completion(success,data,error)
        })
    }
}
class BaasDefaultSignupStrategy : BaasSignupStrategy {
    func signup(username: String, password: String, visibleByTheUser: [String : Any], visibleByFriends: [String : Any], visibleByRegisteredUsers: [String : Any], visibleByAnonymousUsers: [String : Any], completion: BaasBox.BaasCompletion) {
        assert(username != "" && password != "", "Username or password for user creation cannot be empty")
        BaasBox.shared.post(url: "/user", parameters: ["username" : username, "password" : password, "visibleByTheUser" : visibleByTheUser, "visibleByFriends" : visibleByFriends, "visibleByRegisteredUsers" : visibleByRegisteredUsers, "visibleByAnonymousUsers" : visibleByAnonymousUsers], completion: {
            (success, data, error) in
            if success {
                BaasBox.shared.user = BaasUser.init(withDictionary: data as! [String:AnyObject])
                BaasBox.saveCurrentUser()
            }
            completion(success, data, error)
        })
    }
}
class BaasDefaultLogoutStrategy : BaasLogoutStrategy {
    func notAuthorized() {
        print("NEED TO IMPLEMENT NOT AUTHORIZED CUSTOM ACTION")
    }
    func logout() {
        BaasBox.deleteCurrentUser()
    }
}
