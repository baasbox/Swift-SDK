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
//  BaasBox.swift
//  BB SDK
//
//  Created by Luca Cardelli on 19/11/16.
//  Copyright © 2016 Doppionodo. All rights reserved.
//

import Foundation
import UserNotifications
import UIKit


/// The `BaasBox` class.
/// usage is as follows:
///
/// In your app delegate you should setup Baasbox
///
///     let config = BaasConfig()
///
/// Here you can declare some variables, See `BaasConfig` for more data
///
///     BaasBox.setup(url: "your url", appcode: "your appcode", config: config)
///
/// Now you are ready to user BaasBox


public class BaasBox {
    
    static let shared = BaasBox()
    var user = BaasBox.getSavedUser()
    private var base_url : String?
    private var appcode : String?
    private var config : BaasConfig!
    
    private var version = "v1.0"
    
    
    private init() {}

    // MARK : Setters and Getters
    
    /**
     Baasbox setup, call this function in your AppDelegate.
     
     BaasConfig Object:
     ==================
     - timeout: Double
     - retrylogin: Boolean that indicates if the SDK should save the user password encrypted and use it when server returns 401
     - loginStrategy: A login strategy ( user defined functions for login ), if empty the default one will be used
     - signupStrategy: A signup strategy ( user defined functions for signup ), if empty the default one will be used
     - logoutStrategy: A logout strategy ( user defined functions for logout: called on logout or on user not authorized ), if empty the default one will be used
     
     - parameters:
        - url: BaasBox url
        - appcode: BaasBox Appcode
        - config : a BaasConfig Object
     */
    public static func setup(url: String, appcode: String, config: BaasConfig = BaasConfig()) {
        precondition(shared.base_url == nil && shared.appcode == nil, "Cannot invoke setup, already done")
        precondition(url != "","missing url in setup")
        precondition(UIApplication.shared.canOpenURL(URL(string:url)!), "Setup url not valid")
        precondition(appcode != "", "missing appcode in setup")

        shared.base_url = url
        shared.appcode = appcode
        shared.config = config
    }
    
    /**
     Returns the appcode declared in setup.
     
     - return : appcode from setup
 
    */
    public static func getAppcode() -> String? {
        return self.shared.appcode
    }
    
    /**
     Returns the url declared in setup.
     
     - return : url from setup
     
     */
    public static func getBaseUrl() -> String? {
        return self.shared.base_url
    }
    
    /**
     Returns the config declared in setup.
     
     - return : A BaasConfig object
     
     */
    public static func getConfig() -> BaasConfig {
        return self.shared.config
    }
    
    private func check() {
        precondition(base_url != nil && appcode != nil, "Setup not done, you must call BaasBox.setup in your AppDelegate")
    }
    
    // MARK: User Management
    
    /**
        Login the user specified in the parameters
     
        - parameters:
            - username: The username of the user you want to login
            - password: The password of the user you want to login
     */
    public func login(username: String, password: String, completion: BaasCompletion ) {
        check()
        self.config.loginStrategy.login(username: username, password: password, completion: {(success, data, error) in
            completion(success, data, error)
        })
    }
    
    /**
     Login the user specified in the parameters with the specified social platform
     
    - parameters:
        - to: The platform you want to login ( .facebook, .google )
        - token: The token that will be used for the login, you can get it via the third party sdks
     */
    public func socialLogin(to: socialTypes, token: String, completion: BaasCompletion ) {
        self.config.loginStrategy.socialLogin(to: to, token: token, completion: {(success, data, error) in
            completion(success, data, error)
        })
    }

    /**
     Create a user with the specified data
     
     - parameters:
        - username: The username that will be used for the user
        - password: The password that will be used for the user
        - visibleByTheUser: (Optional) Dictionary that will be visible only by yourself
        - visibleByFriends: (Optional) Dictionary that will be visible only by friends
        - visibleByRegisteredUsers: (Optional) Dictionary that will be visible for any registered user
        - visibleByAnonymousUsers: (Optional) Dictionary that will be visible for any user

     */
    public func createUser(username: String, password: String, visibleByTheUser : [String: Any] = [:], visibleByFriends : [String: Any] = [:], visibleByRegisteredUsers : [String: Any] = [:], visibleByAnonymousUsers : [String: Any] = [:], completion: BaasCompletion ) {
        self.config.signupStrategy.signup(username: username, password: password, visibleByTheUser: visibleByTheUser, visibleByFriends: visibleByFriends, visibleByRegisteredUsers: visibleByRegisteredUsers, visibleByAnonymousUsers: visibleByAnonymousUsers, completion: {(success, data, error) in
            completion(success, data, error)
        })
    }
    /**
     Get the details of a specified user
     
     - parameters:
        - username: the username to fetch
     */
    public func getUser(username: String, completion: BaasCompletion ) {
        assert(username != "", "Username of user to fetch cannot be empty")
        get(url: "/user/"+username, parameters: [:], completion: { (success, data, error) in
            completion(success, data, error)
        })
    }
    /**
     Get a list of users
     
     - parameters:
        - parameters: Dictionary of query criteria
     */
    public func getUserList(parameters : [String:AnyHashable] = [:], completion: BaasCompletion) {
        get(url: "/users", parameters: parameters, completion: { (success, data, error) in
            completion(success, data, error)
        })
    }
    /**
     Try reset password of the specified user
     
     Note
     ====
     
     The user need to have the "email" field in the visibleByTheUser dictionary
     
     - parameters:
        - username: the username to try reset
     */
    public func resetPassword(username: String, completion: BaasCompletion) {
        assert(username != "", "Username of user to try reset password cannot be empty")
        get(url: "/user/"+username+"/password/reset", parameters: [:], completion: { (success, data, error) in
            completion(success, data, error)
        })
    }
    
    private static func getSavedUser() -> BaasUser {
        if let encodedUser = UserDefaults.standard.object(forKey: saved_bb_user) {
            let user = NSKeyedUnarchiver.unarchiveObject(with: encodedUser as! Data) as! BaasUser
            return user
        }
        return BaasUser()
    }
    
    /**
     Saves the current stored user
     */
    public static func saveCurrentUser() {
        let encodedUser = NSKeyedArchiver.archivedData(withRootObject: BaasBox.shared.user)
        UserDefaults.standard.set(encodedUser, forKey: saved_bb_user)
    }
    /**
     Remove the current stored user
     */
    public static func deleteCurrentUser() {
        UserDefaults.standard.removeObject(forKey: saved_bb_user)
        UserDefaults.standard.removeObject(forKey: saved_bb_pass)
    }
    
    
    static let saved_bb_pass = "saved_bb_pass"
    
    /**
     Saves the current stored user pass encrypted
     */
    public static func saveUserPass(pass: String) {
        let key = UIDevice.current.identifierForVendor!.uuidString
        let ePass = RNCryptor.encrypt(data: pass.data(using: .utf8)!, withPassword: key)
        UserDefaults.standard.set(ePass, forKey: saved_bb_pass)
    }
    
    private static func getUserPass() -> String? {
        let key = UIDevice.current.identifierForVendor!.uuidString
        if let data = UserDefaults.standard.object(forKey: saved_bb_pass) {
            do {
                let datapass = try RNCryptor.decrypt(data: data as! Data, withPassword: key)
                let pass = String(data: datapass, encoding: .utf8)!
                return pass
            } catch {
                print(error)
                return nil
            }
        }
        return nil
    }


    // MARK: Follow
    
    /**
     Get the follows of a specified user
     
     - parameters:
        - username: the username to fetch
     */
    public func getFollows(username: String, completion: BaasCompletion) {
        assert(username != "", "Username cannot be empty")
        get(url: "/following/"+username, parameters: [:], completion: { (success, data, error) in
            completion(success, data, error)
        })
    }
    /**
     Get the followers of a specified user
     
     - parameters:
        - username: the username to fetch
     */
    public func getFollowers(username: String, completion: BaasCompletion) {
        assert(username != "", "Username cannot be empty")
        get(url: "/followers/"+username, parameters: [:], completion: { (success, data, error) in
            completion(success, data, error)
        })
    }
    
    // MARK: Documents
    
    /**
     Create a document on the specified collection
     
     - parameters:
        - inCollection: The collection where you want to create the document
        - body: Body of the document
     */
    public func createDocument(inCollection coll:String, body: [String: Any], completion: BaasCompletion){
        assert(coll != "", "Collection name cannot be empty")
        post(url: "/document/"+coll, parameters: body, completion: { ( success, data, error ) in
            completion(success, data, error)
        })
    }
    
    /**
     delete a document on the specified collection
     
     - parameters:
        - fromCollection: The collection where you want to delete the document
        - id: id of the document
     */
    public func deleteDocument(fromCollection coll: String, id: String, completion:BaasCompletion) {
        assert(coll != "" && id != "", "Collection name and id of document cannot be empty")
        delete(url: "/document/"+coll+"/"+id, parameters: [:], completion: { (success, data, error) in
            completion(success, data, error)
        })
    }
    
    /**
     Get a document/ a list of documents from the specified collection, you can pass query and pagination criteria
     
     - parameters:
        - fromCollection: The collection where you want to retrieve the document
        - withID: (Optional) the id of the document
        - parameters: (Optional) query criteria
     */
    public func getDocuments(fromCollection coll: String, withID id: String = "", parameters: [String: AnyHashable] = [:], completion: BaasCompletion) {
        assert(coll != "", "Collection name cannot be empty")
        get(url: "/document/"+coll+(id != "" ? "/"+id : ""), parameters: parameters, completion: {(success, data, error) in
            completion(success, data, error)
        })
    }
    
    /**
     Get the number of documents from the specified collection, you can pass query and pagination criteria
     
     - parameters:
        - inCollection: The collection where you want to count the documents
        - parameters: (Optional) query criteria
     */
    public func countDocuments(inCollection coll: String, parameters: [String:AnyHashable] = [:], completion: BaasCompletion) {
        assert(coll != "", "Collection name cannot be empty")
        get(url: "/document/"+coll+"/count", parameters: parameters, completion: {(success, data, error) in
            completion(success, data, error)
        })
    }
    /**
     update a document from the specified collection
     
     - parameters:
        - inCollection: The collection where you want to update the document
        - withID: the id of the document
        - body: (Optional) : new body of the document
     
     NOTE
     ====
     
     The whole document will be overwrited
     */
    public func updateDocument(inCollection coll: String, withID id: String, body: [String: Any], completion: BaasCompletion) {
        assert(coll != "", "Collection name cannot be empty")
        put(url: "/document/"+coll+"/"+id, parameters: body, completion: {(success, data, error) in
            completion(success,data,error)
        })
    }
    
    /**
     Grant access to the specified user to the specified document
     
     - parameters:
        - toDocument: Id of the document
        - inCollection: Name of the collection
        - toUser: Username of the user
        - accessType: enumeration of types of access ( read, delete, all, update )
     */
    public func grantUserAccess(toDocument id: String, inCollection coll: String, toUser user: String, accessType: docAccessTypes, completion: BaasCompletion) {
        assert(coll != "" && id != "" && user != "", "Collection name, id of document and username cannot be empty")
        put(url: "/document/"+coll+"/"+id+"/"+accessType.rawValue+"/user/"+user, parameters: [:], completion: {(success, data, error) in
            completion(success, data, error)
        })
    }
    
    /**
     Grant access to the specified role to the specified document
     
     - parameters:
        - toDocument: Id of the document
        - inCollection: Name of the collection
        - toRole: name of the role
        - accessType: enumeration of types of access ( read, delete, all, update )
     */
    public func grantRoleAccess(toDocument id: String, inCollection coll: String, toRole roleid: String, accessType: docAccessTypes, completion: BaasCompletion) {
        assert(coll != "" && id != "" && roleid != "", "Collection name, id of document and role cannot be empty")
        put(url: "/document/"+coll+"/"+id+"/"+accessType.rawValue+"/role/"+roleid, parameters: [:], completion: {(success, data, error) in
            completion(success, data, error)
        })
    }
    
    /**
     Revoke access to the specified user to the specified document
     
     - parameters:
        - toDocument: Id of the document
        - inCollection: Name of the collection
        - toUser: Username of the user
        - accessType: enumeration of types of access ( read, delete, all, update )
     */
    public func revokeUserAccess(toDocument id: String, inCollection coll: String, toUser user: String, accessType: docAccessTypes, completion: BaasCompletion) {
        assert(coll != "" && id != "" && user != "", "Collection name, id of document and username cannot be empty")
        delete(url: "/document/"+coll+"/"+id+"/"+accessType.rawValue+"/user/"+user, parameters: [:], completion: {(success, data, error) in
            completion(success, data, error)
        })
    }
    
    /**
     Revoke access to the specified role to the specified document
     
     - parameters:
     - toDocument: Id of the document
     - inCollection: Name of the collection
     - toRole: name of the role
     - accessType: enumeration of types of access ( read, delete, all, update )
     */
    public func revokeRoleAccess(toDocument id: String, inCollection coll: String, toRole roleid: String, accessType: docAccessTypes, completion: BaasCompletion) {
        assert(coll != "" && id != "" && roleid != "", "Collection name, id of document and role cannot be empty")
        delete(url: "/document/"+coll+"/"+id+"/"+accessType.rawValue+"/role/"+roleid, parameters: [:], completion: {(success, data, error) in
            completion(success, data, error)
        })
    }
    
    // MARK: Links
    
    /**
     Create a link within two documents with a label
     
     - parameters:
        - label: Label of the link
        - sourceID: Id of the first document
        - destinationID: Id of the second document
     */
    public func createLink(label: String, sourceID source: String, destinationID dest: String, completion: BaasCompletion) {
        assert(label != "" && source != "" && dest != "", "Label, source and destination for link cannot be empty")
        post(url: "/link/"+source+"/"+label+"/"+dest, parameters: [:], completion: {(success, data, error) in
            completion(success, data, error)
        })
    }
    
    /**
     Get list of linked documents, you can pass query and pagination criteria
     
     - parameters:
        - withID: (Optional) The id of the link you want to retrieve
        - parameters: (Optional) query criteria
     */
    public func getLinks(withID id: String = "", parameters: [String:AnyHashable] = [:], completion: BaasCompletion) {
        get(url: "/link"+(id != "" ? "/"+id : ""), parameters: parameters, completion: {(success, data, error) in
            completion(success, data, error)
        })
    }
    
    /**
     Delete the link with the provided id
     
     - parameters:
        - withID: The id of the link you want to delete
     */
    public func deleteLink(withID id: String, completion: BaasCompletion) {
        assert(id != "", "Link id for deletion cannot be empty")
        delete(url: "/link/"+id, parameters: [:], completion: {(success, data, error) in
            completion(success, data, error)
        })
    }
    
    // MARK: Files
    
    /**
     Upload the file given as data
     
     - parameters:
        - data: data of the file you want to upload
        - attachedData : More data you want to store
        - permissions : The permissions of the file uploaded ( see ACL )
 
    */
    public func uploadFile(data: Data, attachedData: [String:AnyHashable] = [:], permissions: [String:AnyHashable] = [:], completion: BaasCompletion) {
        postImage(url: "/file", image:data, attachedData: attachedData, permissions:permissions, completion: {(success, data, error) in
            completion(success, data, error)
        })
    }
    
    /**
     Delete the file with the provided id
     
     - parameters:
        - withID: id of the file to delete
     
     */
    public func deleteFile(withID id: String, completion: BaasCompletion) {
        assert(id != "", "File id for deletion cannot be empty")
        delete(url: "/file/"+id, parameters: [:], completion: {(success, data, error) in
            completion(success, data, error)
        })
    }
    
    /**
     Get the file with the provided id
     
     - parameters:
        - withID: id of the file to get
     
     */
    public func getFile(withID id: String, completion: BaasFileCompletion) {
        assert(id != "", "File id cannot be empty")
        guard id != "" else {
            completion(false, nil, NSError.init(domain: domain, code: -1, userInfo: ["error":"Id of file not provided"]))
            return
        }
        getFile(url: "/file/"+id, completion: {(success, data, error) in
            completion(success, data, error)
        })
    }
    
    /**
     Get the file details with the provided id
     
     - parameters:
        - withID: id of the file to get
     
     */
    public func getFileDetails(withID id: String, completion: BaasCompletion) {
        assert(id != "", "File id for details cannot be empty")
        guard id != "" else {
            completion(false, nil, NSError.init(domain: domain, code: -1, userInfo: ["error":"Id of file not provided"]))
            return
        }
        get(url: "/file/details/"+id, parameters: [:], completion: {(success, data, error) in
            completion(success, data, error)
        })
    }
    
    /**
     Get a list of file details, you can pass query criteria
     
     - parameters:
        - parameters: Query criteria
     
     */
    public func getFilesDetails(parameters: [String: AnyHashable] = [:], completion: BaasCompletion) {
        get(url: "/file/details", parameters: parameters, completion: {(success,data,error) in
            completion(success, data, error)
        })
    }
    
    /**
     Grant access to the specified user to the specified file
     
     - parameters:
        - toFile: Id of the document
        - inCollection: Name of the collection
        - toUser: Username of the user
        - accessType: enumeration of types of access ( read, delete, all, update )
     */
    public func grantUserAccess(toFile id: String, toUser userid: String, accessType: docAccessTypes, completion: BaasCompletion) {
        assert(id != "" && userid != "", "ID of file and username cannot be empty")
        put(url: "/file/"+id+"/"+accessType.rawValue+"/user/"+userid, parameters: [:], completion: {(success, data, error) in
            completion(success, data, error)
        })
    }
    
    /**
     Grant access to the specified role to the specified file
     
     - parameters:
        - toFile: Id of the document
        - inCollection: Name of the collection
        - toRole: name of the role
        - accessType: enumeration of types of access ( read, delete, all, update )
     */
    public func grantRoleAccess(toFile id: String, toRole roleid: String, accessType: docAccessTypes, completion: BaasCompletion) {
        assert(id != "" && roleid != "", "ID of file and role cannot be empty")
        put(url: "/file/"+id+"/"+accessType.rawValue+"/role/"+roleid, parameters: [:], completion: {(success, data, error) in
            completion(success, data, error)
        })
    }
    
    /**
     Revoke access to the specified user to the specified file
     
     - parameters:
        - toFile: Id of the document
        - inCollection: Name of the collection
        - toUser: Username of the user
        - accessType: enumeration of types of access ( read, delete, all, update )
     */
    public func revokeUserAccess(toFile id: String, toUser userid: String, accessType: docAccessTypes, completion: BaasCompletion) {
        assert(id != "" && userid != "", "ID of file and username cannot be empty")
        delete(url: "/file/"+id+"/"+accessType.rawValue+"/user/"+userid, parameters: [:], completion: {(success, data, error) in
            completion(success, data, error)
        })
    }
    
    /**
     Revoke access to the specified role to the specified file
     
     - parameters:
        - toFile: Id of the document
        - inCollection: Name of the collection
        - toRole: name of the role
        - accessType: enumeration of types of access ( read, delete, all, update )
     */
    public func revokeRoleAccess(toFile id: String, toRole roleid: String, accessType: docAccessTypes, completion: BaasCompletion) {
        assert(id != "" && roleid != "", "ID of file and role cannot be empty")
        delete(url: "/file/"+id+"/"+accessType.rawValue+"/role/"+roleid, parameters: [:], completion: {(success, data, error) in
            completion(success, data, error)
        })
    }
    
    // MARK: Assets
    
    /**
     Retrieve the asset with the specified name
     
     - parameters:
        - name: name of the asset
     */
    public func getAsset(name: String, completion: BaasFileCompletion) {
        assert(name != "", "Name of the asset cannot be empty")
        guard name != "" else {
            completion(false, nil, NSError.init(domain: domain, code: -1, userInfo: ["error":"name of the asset not provided"]))
            return
        }
        getFile(url: "/asset/"+name, completion: {(success, data, error) in
            completion(success,data,error)
        })
    }
    
    // MARK: Push Notifications
    
    /**
     Ask the user to enable push notification.
     You need to add to your AppDelegate:
     
     import UserNotification
     extension UNUserNotificationDelegate
     if #available(iOS 10.0, *){
        UNUserNotificationCenter.current().delegate = self
     }
     
     for ios10
     
     */
    public func askToEnablePushNotifications() {
        if #available(iOS 10.0, *){
            UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound, .alert], completionHandler: {(granted, error) in
                if (granted)
                {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            })
        } else {
            let type: UIUserNotificationType = [UIUserNotificationType.badge, UIUserNotificationType.alert, UIUserNotificationType.sound];
            let setting = UIUserNotificationSettings(types: type, categories: nil);
            UIApplication.shared.registerUserNotificationSettings(setting);
            UIApplication.shared.registerForRemoteNotifications();
        }
    }
    
    /**
     Add this method in AppDelegate:
     
      didRegisterForRemoteNotificationsWithDeviceToken
     
     */
    public func enablePushNotifications(deviceToken: Data, completion: BaasCompletion) {
        let token = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        self.user.pushToken = token
        if !self.user.pushEnabled {
            put(url: "/push/enable/ios/"+token, parameters: [:], completion: {(success, data, error) in
                if success {
                    self.user.pushEnabled = true
                }
                completion(success, data, error)
            })
        }
    }
    
    /**
     Sends a push notification to the specified users
     */
    public func sendNotification(message: String, users: [String], profiles: [pushProfiles] = [.one], sound:String = "", badge: Int = 1, actionLocalizedKey: String = "", localizedKey: String = "", localizedArguments: [String] = [], custom: [String: AnyHashable] = [:], collapse_key:String = "", time_to_live: Int = 2419200, content_available: Int = 1, category: String = "", completion:BaasCompletion) {
        postNotif(url: "/push/message", parameters: ["message":message, "users":users, "profiles":profiles, "sound":sound, "badge":badge, "actionLocalizedKey":actionLocalizedKey, "localizedKey":localizedKey, "localizedArguments":localizedArguments, "custom":custom, "collapse_key":collapse_key, "time_to_live":time_to_live, "content-available": content_available, "category":category], completion: {(success, data, error) in
            completion(success, data, error)
        })
    }
    
    // MARK: Pass Through
    
    private func getHeaders(contType: String = "application/json") -> [String: String] {
        var h = [String:String]()
        h["cache-control"] = "no-cache"
        h["Content-Type"] = contType
        h["x-baasbox-appcode"] = self.appcode
        h["User-Agent"] = "BaasBox Swift SDK - "+self.version
        if self.user.isAuthenticated() {
            h["x-bb-session"] = self.user.token
        }
        return h
    }
    /**
     HTTP GET, you can use this to call plugins
     
     - parameters:
        - url: the endpoint to call ( note: without the base url ) eg: /plugins/baasbox.plugin
        - parameters: list of parameters for the query
     */
    public func get(url: String, parameters:[String:AnyHashable], completion: BaasCompletion) {
        check()
        let requestUrl = self.base_url!+url+"?"+parameters.stringFromHttpParameters()
        let request = NSMutableURLRequest(url: URL(string: requestUrl)!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: self.config.timeout)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = getHeaders()

        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                completion(false, nil, error)
            } else {
                if let data = data {
                    let json = data.convertToDictionary()
                    let sc = (response as! HTTPURLResponse).statusCode
                    if sc >= 400 {
                        if self.config.retrylogin && sc == 401 && !self.isRetry {
                            self.retryRequest(request: request, error: NSError.init(domain: self.domain, code: sc, userInfo: ["message":json?["message"] as! String]), completion: { (success, data, error) in
                                completion(success,data,error)
                            })
                        } else {
                            if sc == 401 && !self.config.retrylogin { self.config.logoutStrategy.notAuthorized() }
                            completion(false, nil, NSError.init(domain: self.domain, code: sc, userInfo: ["message":json?["message"] as! String]))
                        }
                        return
                    }
                    if ( json?["result"] as! String == "ok" ) {
                        completion(true, json?["data"], nil)
                    } else { completion(false, nil, NSError.init(domain: self.domain, code: sc, userInfo: ["message":json?["message"] as! String])) }
                }
            }
        })
        dataTask.resume()
    }
    /**
     HTTP POST, you can use this to call plugins
     
     - parameters:
        - url: the endpoint to call ( note: without the base url ) eg: /plugins/baasbox.plugin
        - parameters: list of parameters for the query
     */
    public func post(url: String, parameters:[String:Any], completion: BaasCompletion) {
        check()
        let requestUrl = self.base_url!+url
        let request = NSMutableURLRequest(url: URL(string: requestUrl)!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: self.config.timeout)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        guard let body = parameters.convertToData() else {
            fatalError("Cannot convert parameters to data")
        }
        request.httpBody = body
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                completion(false, nil, error)
            } else {
                if let data = data {
                    let json = data.convertToDictionary()
                    let sc = (response as! HTTPURLResponse).statusCode
                    if sc >= 400 {
                        if self.config.retrylogin && sc == 401 && !self.isRetry {
                            self.retryRequest(request: request, error: NSError.init(domain: self.domain, code: sc, userInfo: ["message":json?["message"] as! String]), completion: { (success, data, error) in
                                completion(success,data,error)
                            })
                        } else {
                            if sc == 401 && !self.config.retrylogin { self.config.logoutStrategy.notAuthorized() }
                            completion(false, nil, NSError.init(domain: self.domain, code: sc, userInfo: ["message":json?["message"] as! String]))
                        }
                        return
                    }
                    if ( json?["result"] as! String == "ok" ) {
                        completion(true, json?["data"], nil)
                    } else { completion(false, nil, NSError.init(domain: self.domain, code: 2, userInfo: ["message":json?["message"] as! String])) }
                }
            }
        })
        
        dataTask.resume()
    }
    /**
     HTTP PUT, you can use this to call plugins
     
     - parameters:
        - url: the endpoint to call ( note: without the base url ) eg: /plugins/baasbox.plugin
        - parameters: list of parameters for the query
     */
    public func put(url: String, parameters:[String:Any], completion: BaasCompletion) {
        check()
        let requestUrl = self.base_url!+url
        let request = NSMutableURLRequest(url: URL(string: requestUrl)!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: self.config.timeout)
        request.httpMethod = "PUT"
        request.allHTTPHeaderFields = getHeaders()
        guard let body = parameters.convertToData() else {
            fatalError("Cannot convert parameters to data")
        }
        request.httpBody = body
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                completion(false, nil, error)
            } else {
                if let data = data {
                    let json = data.convertToDictionary()
                    let sc = (response as! HTTPURLResponse).statusCode
                    if sc >= 400 {
                        if self.config.retrylogin && sc == 401 && !self.isRetry {
                            self.retryRequest(request: request, error: NSError.init(domain: self.domain, code: sc, userInfo: ["message":json?["message"] as! String]), completion: { (success, data, error) in
                                completion(success,data,error)
                            })
                        } else {
                            if sc == 401 && !self.config.retrylogin { self.config.logoutStrategy.notAuthorized() }
                            completion(false, nil, NSError.init(domain: self.domain, code: sc, userInfo: ["message":json?["message"] as! String]))
                        }
                        return
                    }
                    if ( json?["result"] as! String == "ok" ) {
                        completion(true, json?["data"], nil)
                    } else { completion(false, nil, NSError.init(domain: self.domain, code: 2, userInfo: ["message":json?["message"] as! String])) }
                }
            }
        })
        dataTask.resume()
    }
    /**
     HTTP DELETE, you can use this to call plugins
     
     - parameters:
        - url: the endpoint to call ( note: without the base url ) eg: /plugins/baasbox.plugin
        - parameters: list of parameters for the query
     */
    public func delete(url: String, parameters:[String:Any], completion: BaasCompletion) {
        check()
        let requestUrl = self.base_url!+url
        let request = NSMutableURLRequest(url: URL(string: requestUrl)!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: self.config.timeout)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        guard let body = parameters.convertToData() else {
            fatalError("Cannot convert parameters to data")
        }
        request.httpBody = body
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                completion(false, nil, error)
            } else {
                if let data = data {
                    let json = data.convertToDictionary()
                    let sc = (response as! HTTPURLResponse).statusCode
                    if sc >= 400 {
                        if self.config.retrylogin && sc == 401 && !self.isRetry {
                            self.retryRequest(request: request, error: NSError.init(domain: self.domain, code: sc, userInfo: ["message":json?["message"] as! String]), completion: { (success, data, error) in
                                completion(success,data,error)
                            })
                        } else {
                            if sc == 401 && !self.config.retrylogin { self.config.logoutStrategy.notAuthorized() }
                            completion(false, nil, NSError.init(domain: self.domain, code: sc, userInfo: ["message":json?["message"] as! String]))
                        }
                        return
                    }
                    if ( json?["result"] as! String == "ok" ) {
                        completion(true, json?["data"], nil)
                    } else { completion(false, nil, NSError.init(domain: self.domain, code: 2, userInfo: ["message":json?["message"] as! String])) }
                }
            }
        })
        dataTask.resume()
    }
    private func retryRequest(request: NSMutableURLRequest, isPostImage:Bool = false, error:Error, completion: BaasCompletion) {
        guard let pass = BaasBox.getUserPass() else {
            print("pass non salvata")
            completion(false, nil, error)
            return
        }
        print("retying login")
        DispatchQueue(label: "retry").async {
            self.retryLogin(pass: pass, completion: {(success) in
                if !success {
                    self.config.logoutStrategy.notAuthorized()
                    completion(false, nil, error)
                } else {
                    let session = URLSession.shared
                    request.allHTTPHeaderFields = !isPostImage ? self.getHeaders() : self.getHeaders(contType: "multipart/form-data; boundary="+self.boundary)
                    let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
                        if (error != nil) {
                            completion(false, nil, error)
                        } else {
                            if let data = data {
                                let json = data.convertToDictionary()
                                let sc = (response as! HTTPURLResponse).statusCode
                                if sc >= 400 {
                                    completion(false, nil, NSError.init(domain: self.domain, code: sc, userInfo: ["message":json?["message"] as! String]))
                                    return
                                }
                                if ( json?["result"] as! String == "ok" ) {
                                    completion(true, json?["data"], nil)
                                } else { completion(false, nil, NSError.init(domain: self.domain, code: 2, userInfo: ["message":json?["message"] as! String])) }
                            }
                        }
                    })
                    dataTask.resume()
                }
            })
        }
    }
    private var isRetry = false
    private func retryLogin(pass: String, completion: @escaping (Bool) -> Void) {
        self.isRetry = true
        if !BaasBox.shared.user.isSocialLogin {
            self.config.loginStrategy.login(username: self.user.username, password: pass, completion: {(success, data, error) in
                self.isRetry = false
                completion(success)
            })
        } else {
            self.config.loginStrategy.socialLogin(to: getSocialType(s: self.user.socialType), token: pass, completion: { (success, data, error) in
                self.isRetry = false
                completion(success)
            })
        }
    }
    private func getSocialType(s: String) -> socialTypes {
        switch s {
        case "facebook":
            return .facebook
        case "google":
            return .google
        default:
            return .facebook
        }
    }
    
    
    private func postImage(url: String, image:Data, attachedData: [String: AnyHashable] = [:], permissions: [String: AnyHashable] = [:], completion: BaasCompletion) {
        check()
        let requestUrl = self.base_url!+url
        let request = NSMutableURLRequest(url: URL(string: requestUrl)!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: self.config.timeout)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders(contType: "multipart/form-data; boundary="+boundary)
        request.httpBody = createImageBody(image: image, attachedData: attachedData, permissions: permissions)
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                completion(false, nil, error)
            } else {
                if let data = data {
                    let json = data.convertToDictionary()
                    let sc = (response as! HTTPURLResponse).statusCode
                    if sc >= 400 {
                        if self.config.retrylogin && sc == 401 {
                            self.retryRequest(request: request, isPostImage: true, error: NSError.init(domain: self.domain, code: sc, userInfo: ["message":json?["message"] as! String]), completion: { (success, data, error) in
                                completion(success,data,error)
                            })
                        } else {
                            if sc == 401 && !self.config.retrylogin { self.config.logoutStrategy.notAuthorized() }
                            completion(false, nil, NSError.init(domain: self.domain, code: sc, userInfo: ["message":json?["message"] as! String]))
                        }
                        return
                    }
                    if ( json?["result"] as! String == "ok" ) {
                        completion(true, json?["data"], nil)
                    } else { completion(false, nil, NSError.init(domain: self.domain, code: 2, userInfo: ["message":json?["message"] as! String])) }
                }
            }
        })
        dataTask.resume()
    }

    private func createImageBody(image: Data, attachedData: [String:AnyHashable] = [:], permissions: [String:AnyHashable] = [:]) -> Data {
        let body = NSMutableData()
        let mimetype = "image/jpeg"
        body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Disposition:form-data; name=\"file\"; filename=\"\(NSUUID().uuidString)\"\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
        body.append(image)
        body.append("\r\n".data(using: String.Encoding.utf8)!)
        body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Disposition:form-data; name=\"attachedData\"\r\n\r\n".data(using: String.Encoding.utf8)!)
        guard let json = attachedData.convertToData() else {
            fatalError("Cannot convert parameters to data")
        }
        body.append(json)
        body.append("\r\n".data(using: String.Encoding.utf8)!)
        body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Disposition:form-data; name=\"acl\"\r\n\r\n".data(using: String.Encoding.utf8)!)
        guard let perm = permissions.convertToData() else {
            fatalError("Cannot convert parameters to data")
        }
        body.append(perm)
        body.append("\r\n".data(using: String.Encoding.utf8)!)
        body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
        
        return body as Data
    }
    
    private func getFile(url: String, completion: BaasFileCompletion) {
        let request = NSMutableURLRequest(url: URL(string: self.base_url!+url)!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: self.config.timeout)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = getHeaders()
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                completion(false, nil, error)
            } else {
                if let data = data {
                    let sc = (response as! HTTPURLResponse).statusCode
                    if sc >= 400 {
                        let json = data.convertToDictionary()
                        completion(false, nil, NSError.init(domain: self.domain, code: sc, userInfo: ["message":json?["message"] as! String]))
                        return
                    }
                    completion(true, data, nil)
                }
            }
        })
        dataTask.resume()
    }
    
    private func postNotif(url: String, parameters:[String:Any], completion: BaasCompletion) {
        check()
        let requestUrl = self.base_url!+url
        let request = NSMutableURLRequest(url: URL(string: requestUrl)!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: self.config.timeout)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        guard let body = parameters.convertToData() else {
            fatalError("Cannot convert parameters to data")
        }
        request.httpBody = body
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                completion(false, nil, error)
            } else {
                if let data = data {
                    let json = data.convertToDictionary()
                    let sc = (response as! HTTPURLResponse).statusCode
                    if sc >= 400 {
                        if self.config.retrylogin && sc == 401 {
                            self.retryRequest(request: request, error: NSError.init(domain: self.domain, code: sc, userInfo: ["message":json?["message"] as! String]), completion: { (success, data, error) in
                                completion(success,data,error)
                            })
                        } else {
                            completion(false, nil, NSError.init(domain: self.domain, code: sc, userInfo: ["message":json?["message"] as! String]))
                        }
                        return
                    }
                    completion(true, json, nil)
                }
            }
        })
        dataTask.resume()
    }
    
    // MARK: Variables
    
    public typealias BaasCompletion = (( _ success : Bool, _ data : Any?, _ error: Error? ) -> Void)!
    public typealias BaasFileCompletion = (( _ success : Bool, _ data : Data?, _ error: Error? ) -> Void)!
    
    // MARK: Enums
    
    /// Enum the possible social logins offered by BaasBox
    public enum socialTypes : String {
        /// Facebook string for social login
        case facebook = "facebook"
        /// Google string for social login
        case google = "google"
    }
    /// Enum the possible access types for documents and files
    public enum docAccessTypes : String {
        /// User/role can read
        case read = "read"
        /// User/role can update
        case update = "update"
        /// User/role can delete
        case delete = "delete"
        /// User/role can read/update/delete
        case all = "all"
        /// Used internally to 
        case none = ""
    }
    /// Enum the possible app profiles for push notifications
    public enum pushProfiles : Int {
        /// First profile
        case one = 1
        /// Second profile
        case two = 2
        /// Third profile
        case three = 3
    }
    
    private let domain = "com.baasbox.sdk"
    private let boundary = "BAASBOX_BOUNDARY_STRING"
    static let saved_bb_user = "saved_bb_user"
}

extension Dictionary {
    func stringFromHttpParameters() -> String {
        let parameterArray = self.map { (key, value) -> String in
            let percentEscapedKey = (key as! String).addingPercentEncodingForURLQueryValue()!
            let percentEscapedValue = (value as! String).addingPercentEncodingForURLQueryValue()!
            return "\(percentEscapedKey)=\(percentEscapedValue)"
        }
        return parameterArray.joined(separator: "&")
    }
    func convertToData() -> Data? {
        do {
            return try JSONSerialization.data(withJSONObject: self, options: [])
        } catch let error {
            print("errore convert", error)
        }
        return nil
    }
}
extension String {
    func addingPercentEncodingForURLQueryValue() -> String? {
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        return self.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
    }
}
extension Data {
    func convertToDictionary() -> [String: AnyObject]? {
        do {
            return try JSONSerialization.jsonObject(with: self, options: []) as? [String:AnyObject]
        } catch let error as NSError {
            print("ERRORE CONVERT TO JSON",error)
        }
        return nil
    }
}
