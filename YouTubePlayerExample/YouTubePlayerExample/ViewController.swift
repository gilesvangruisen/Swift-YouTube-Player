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
    
    @IBAction func play(_ sender: UIButton) {
        if playerView.ready {
            if playerView.playerState != YouTubePlayerState.playing {
                playerView.play()
                playButton.setTitle("Pause", for: .normal)
            } else {
                playerView.pause()
                playButton.setTitle("Play", for: .normal)
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
        playerView.playerVars = [
            "playsinline": "1",
            "controls": "0",
            "showinfo": "0"
            ] as YouTubePlayerView.YouTubePlayerParameters
        playerView.loadVideoID("s4thQcgLCqk")
    }

    @IBAction func loadPlaylist(_ sender: UIButton) {
        playerView.loadPlaylistID("PL70DEC2B0568B5469")
    }
    
    @IBAction func currentTime(_ sender: UIButton) {
        playerView.getCurrentTime { (val) in
            DispatchQueue.main.async {
                let title = String(format: "Current Time %@", val ?? "0")
                self.currentTimeButton.setTitle(title, for: .normal)
            }
        }
    }
    
    @IBAction func duration(_ sender: UIButton) {
        playerView.getDuration { (val) in
            DispatchQueue.main.async {
                let title = String(format: "Duration %@", val ?? "0")
                self.durationButton.setTitle(title, for: .normal)
            }
        }
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

