//
//  AppDelegate.swift
//  S3Uploader
//
//  Created by Guido Marucci Blas on 2/15/16.
//  Copyright © 2016 guidomb. All rights reserved.
//

import UIKit

public var AvoidUpload = false

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        let cognitoIdentityPoolId = NSBundle.mainBundle().infoDictionary?["AWSIdentityPool"] as! String
        let credentialProvider = AWSCognitoCredentialsProvider(
            regionType: .USEast1,
            identityPoolId: cognitoIdentityPoolId)
        let configuration = AWSServiceConfiguration(
            region: .USEast1,
            credentialsProvider: credentialProvider)
        
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
        
        
        print("Checking if there are tasks that need to be resumed")
        let uploadProgress: AWSS3TransferUtilityUploadProgressBlock = { task, _, totalBytesSent, totalBytesExpectedToSend in
            let progress = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
            print("task \(task.taskIdentifier) progres: \(progress)")
        }
        let completion: AWSS3TransferUtilityUploadCompletionHandlerBlock = { task, maybeError in
            if let error = maybeError {
                print("Task \(task.taskIdentifier) Error uploading file \(error)")
                task.cancel()
                // TODO we should re-trigger an upload task for this file
            } else {
                print("Task \(task.taskIdentifier) File uploaded!")
            }
        }
        let transferUtility = AWSS3TransferUtility.defaultS3TransferUtility()
        transferUtility.enumerateToAssignBlocksForUploadTask({ (task, progressPointer, completionPointer) -> Void in
            progressPointer.memory = uploadProgress
            completionPointer.memory = completion
        }, downloadTask: nil)
            
            
        transferUtility.getUploadTasks().continueWithBlock { task in
            if let tasks = task.result as? [AWSS3TransferUtilityUploadTask] {
                if tasks.isEmpty {
                    print("No tasks to be resumed")
                } else {
                    print("There are \(tasks.count) to be resumed")
                    for task in tasks {
                        print("Resuming task: \(task.taskIdentifier)")
                        task.resume()
                    }
                    AvoidUpload = true
                }
            }
            return nil
        }
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        print("Application will resign active")
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("Application did enter background")
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        print("Application will enter foreground")
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("application did become active")
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        print("application will terminate")
    }
    
    func application(application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: () -> Void) {
        AWSS3TransferUtility.interceptApplication(application, handleEventsForBackgroundURLSession: identifier, completionHandler: completionHandler)
    }


}

