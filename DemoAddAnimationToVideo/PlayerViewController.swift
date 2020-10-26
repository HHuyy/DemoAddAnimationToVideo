//
//  PlayerViewController.swift
//  DemoAddAnimationToVideo
//
//  Created by Brite Solutions on 10/26/20.
//  Copyright © 2020 huy. All rights reserved.
//

import UIKit
import AVKit
import Photos

class PlayerViewController: UIViewController {
  var videoURL: URL!
  
  private var player: AVPlayer!
  private var playerLayer: AVPlayerLayer!
  
  @IBOutlet weak var videoView: UIView!
  
  @IBAction func saveVideoButtonTapped(_ sender: Any) {
    PHPhotoLibrary.requestAuthorization { [weak self] status in
      switch status {
      case .authorized:
        self?.saveVideoToPhotos()
      default:
        print("Photos permissions not granted.")
        return
      }
    }
  }
  
  private func saveVideoToPhotos() {
    PHPhotoLibrary.shared().performChanges({
      PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.videoURL)
    }) { [weak self] (isSaved, error) in
      if isSaved {
        print("Video saved.")
      } else {
        print("Cannot save video.")
        print(error ?? "unknown error")
      }
      DispatchQueue.main.async {
        self?.navigationController?.popViewController(animated: true)
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
        
    player = AVPlayer(url: videoURL)
    playerLayer = AVPlayerLayer(player: player)
    playerLayer.frame = videoView.bounds
    videoView.layer.addSublayer(playerLayer)
    player.play()
    
    NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: nil,
      queue: nil) { [weak self] _ in self?.restart() }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(false, animated: animated)
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    
    playerLayer.frame = videoView.bounds
  }
  
  private func restart() {
    player.seek(to: .zero)
    player.play()
  }
  
  deinit {
    NotificationCenter.default.removeObserver(
      self,
      name: .AVPlayerItemDidPlayToEndTime,
      object: nil)
  }
}
