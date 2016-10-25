//
//  ViewController.swift
//  YouTubePlayerExample
//
//  Created by Giles Van Gruisen on 1/31/15.
//  Copyright (c) 2015 Giles Van Gruisen. All rights reserved.
//

import UIKit
import YouTubePlayer

class ViewController: UIViewController {

    @IBOutlet var playerView: YouTubePlayerView!
    @IBOutlet var playButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //for triggering playerReady events
        playerView.delegate = playerView
    }

    @IBAction func play(_ sender: UIButton) {
        if playerView.ready {
            if playerView.playerState != YouTubePlayerState.Playing {
                playerView.play()
                playButton.setTitle("Pause", for: UIControlState())
            } else {
                playerView.pause()
                playButton.setTitle("Play", for: UIControlState())
            }
        }
    }

    @IBAction func prev(_ sender: UIButton) {
        playerView.previousVideo()
    }

    @IBAction func next(_ sender: UIButton) {
        playerView.nextVideo()
    }

    @IBAction func loadVideo(_ sender: UIButton) {
        
        //remove any subview related with loading spinner if it existed.
        playerView.removeActivityIndicatorView()
        
        //show loading spinner
        playerView.showActivityIndicatorView()
        
        playerView.playerVars = ["playsinline": "1" as AnyObject]
        playerView.loadVideoID("KvtT3UyhibQ")
    }

    @IBAction func loadPlaylist(_ sender: UIButton) {
        
        //remove any subview related with loading spinner if it existed.
        playerView.removeActivityIndicatorView()
        //show loading spinner
        playerView.showActivityIndicatorView()
        
        playerView.loadPlaylistID("RDe-ORhEE9VVg")
    }

    func showAlert(_ message: String) {
        self.present(alertWithMessage(message), animated: true, completion: nil)
    }

    func alertWithMessage(_ message: String) -> UIAlertController {
        let alertController =  UIAlertController(title: "", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))

        return alertController
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

