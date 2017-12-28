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
    @IBOutlet var currentTimeButton: UIButton!
    @IBOutlet var durationButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func play(sender: UIButton) {
        if playerView.ready {
            if playerView.playerState != YouTubePlayerState.Playing {
                playerView.play()
                playButton.setTitle("Pause", for: .normal)
            } else {
                playerView.pause()
                playButton.setTitle("Play", for: .normal)
            }
        }
    }

    @IBAction func prev(sender: UIButton) {
        playerView.previousVideo()
    }

    @IBAction func next(sender: UIButton) {
        playerView.nextVideo()
    }

    @IBAction func loadVideo(sender: UIButton) {
        playerView.playerVars = [
            "playsinline": "1" as AnyObject,
            "controls": "0" as AnyObject,
            "showinfo": "0" as AnyObject
        ]
        playerView.loadVideoID("9bZkp7q19f0")
    }

    @IBAction func loadPlaylist(sender: UIButton) {
        playerView.loadPlaylistID("PLu8-5UhSJGkIs4Hazj-yjcwloIWz6gMMX")
    }
    
    @IBAction func currentTime(sender: UIButton) {
        let title = String(format: "Current Time %@", playerView.getCurrentTime() ?? "0")
        currentTimeButton.setTitle(title, for: .normal)
    }
    
    @IBAction func duration(sender: UIButton) {
        let title = String(format: "Duration %@", playerView.getDuration() ?? "0")
        durationButton.setTitle(title, for: .normal)
    }

    func showAlert(message: String) {
        self.present(alertWithMessage(message: message), animated: true, completion: nil)
    }

    func alertWithMessage(message: String) -> UIAlertController {
        let alertController =  UIAlertController(title: "", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))

        return alertController
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

