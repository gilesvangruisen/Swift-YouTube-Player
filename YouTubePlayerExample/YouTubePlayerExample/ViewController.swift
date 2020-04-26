//
//  ViewController.swift
//  YouTubePlayerExample
//
//  Created by Giles Van Gruisen on 1/31/15.
//  Copyright (c) 2015 Giles Van Gruisen. All rights reserved.
//

import WebKit
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
        if self.playerView.ready {
            if self.playerView.playerState != YouTubePlayerState.Playing {
                self.playerView.play()
                self.playButton.setTitle("Pause", for: .normal)
            } else {
                self.playerView.pause()
                self.playButton.setTitle("Play", for: .normal)
            }
        }
    }

    @IBAction func prev(sender: UIButton) {
        self.playerView.previousVideo()
    }

    @IBAction func next(sender: UIButton) {
        self.playerView.nextVideo()
    }

    @IBAction func loadVideo(sender: UIButton) {
        self.playerView.playerVars = [
            "playsinline": "1",
            "controls": "0",
            "showinfo": "0"
            ] as YouTubePlayerView.YouTubePlayerParameters
        self.playerView.loadVideoId("qIcTM8WXFjk")
    }

    @IBAction func loadPlaylist(sender: UIButton) {
        self.playerView.loadPlaylistId("PL4dX1IHww9p0K8IlTvPnwmBpgdh0rl_Io")
    }
    
    @IBAction func currentTime(sender: UIButton) {
        self.playerView.getCurrentTime(completion: { time in
            let title = String(format: "Current Time %.2f", time)
            self.currentTimeButton.setTitle(title, for: .normal)
        })
    }
    
    @IBAction func duration(sender: UIButton) {
        self.playerView.getDuration(completion: { time in
            let title = String(format: "Duration %.2f", time)
            self.durationButton.setTitle(title, for: .normal)
        })
    }

    func showAlert(message: String) {
        self.present(self.alertWithMessage(message: message), animated: true, completion: nil)
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

