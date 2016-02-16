//
//  ViewController.swift
//  S3Uploader
//
//  Created by Guido Marucci Blas on 2/15/16.
//  Copyright © 2016 guidomb. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var progressBar: UIProgressView!

    override func viewDidLoad() {
        super.viewDidLoad()
        let bucket = NSBundle.mainBundle().infoDictionary?["AWSS3Bucket"] as! String
        progressBar.progress = 0
        if AvoidUpload {
            print("New upload has been avoided")
            return
        }
        // Do any additional setup after loading the view, typically from a nib.
        if let archiveURL = NSBundle.mainBundle().URLForResource("archive", withExtension: "zip") {
            let expression = AWSS3TransferUtilityUploadExpression()
            expression.uploadProgress = { _, _, totalBytesSent, totalBytesExpectedToSend in
                let progress = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
                dispatch_async(dispatch_get_main_queue()) { self.progressBar.progress = progress }
                print("progres: \(progress)")
            }
            let transferUtility = AWSS3TransferUtility.defaultS3TransferUtility()
            transferUtility.uploadFile(archiveURL,
                bucket: bucket,
                key: "archive.zip",
                contentType: "application/zip",
                expression: expression) { task, maybeError in
                    if let error = maybeError {
                        print("Error uploading file \(error)")
                    } else {
                        print("File uploaded!")
                    }
            }
            .continueWithBlock { task in
                if let error = task.error {
                    print("Task error: \(error)")
                }
                if let exception = task.exception {
                    print("Task exception: \(exception)")
                }
                if let _ = task.result {
                    print("Uploading file ...")
                }
                
                return nil;
            }
            
        } else {
            print("Archive not found!")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

