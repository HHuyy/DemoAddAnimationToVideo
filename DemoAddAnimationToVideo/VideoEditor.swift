//
//  VideoEditor.swift
//  DemoAddAnimationToVideo
//
//  Created by Brite Solutions on 10/26/20.
//  Copyright © 2020 huy. All rights reserved.
//

import UIKit
import AVFoundation

class VideoEditor {
  func makeBirthdayCard(fromVideoAt videoURL: URL, forName name: String, onComplete: @escaping (URL?) -> Void) {
//    onComplete(videoURL)
    let asset = AVURLAsset(url: videoURL)
    let composition = AVMutableComposition()
    guard let compositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid), let assetTrack = asset.tracks(withMediaType: .video).first
    else {
      print("Something is wrong with the asset.")
      onComplete(nil)
      return
    }
    
    do {
      // Specifies the time range in video.
      let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
      // Enter the entire video from the asset into the video track of the composition.
      try compositionTrack.insertTimeRange(timeRange, of: assetTrack, at: .zero)
      
      // If the asset also contains an audio track, add an audio track to the composition then enter the audio of the asset into the track.
      if let audioAssetTrack = asset.tracks(withMediaType: .audio).first,
        let compositionAudioTrack = composition.addMutableTrack(
          withMediaType: .audio,
          preferredTrackID: kCMPersistentTrackID_Invalid) {
        try compositionAudioTrack.insertTimeRange(
          timeRange,
          of: audioAssetTrack,
          at: .zero)
      }
    } catch {
      print(error)
      onComplete(nil)
      return
    }
    
    compositionTrack.preferredTransform = assetTrack.preferredTransform
    let videoInfo = orientation(from: assetTrack.preferredTransform)
    let videoSize: CGSize
    if videoInfo.isPortrait {
      videoSize = CGSize(
        width: assetTrack.naturalSize.height,
        height: assetTrack.naturalSize.width)
    } else {
      videoSize = assetTrack.naturalSize
    }
    
    let backgroundLayer = CALayer()
    backgroundLayer.frame = CGRect(origin: .zero, size: videoSize)
    let videoLayer = CALayer()
    videoLayer.frame = CGRect(origin: .zero, size: videoSize)
    let overlayLayer = CALayer()
    overlayLayer.frame = CGRect(origin: .zero, size: videoSize)
    
//    backgroundLayer.backgroundColor = UIColor(named: "rw-green")?.cgColor
//    videoLayer.frame = CGRect(
//      x: 20,
//      y: 20,
//      width: videoSize.width - 40,
//      height: videoSize.height - 40)
//    backgroundLayer.contents = UIImage(named: "background")?.cgImage
//    backgroundLayer.contentsGravity = .resizeAspectFill
    
    addImage(to: overlayLayer, videoSize: videoSize)
    
//    addConfetti(to: overlayLayer)
    
    add(
    text: "Happy Birthday, /n\(name)",
    to: overlayLayer,
    videoSize: videoSize)
    
    let outputLayer = CALayer()
    outputLayer.frame = CGRect(origin: .zero, size: videoSize)
    outputLayer.addSublayer(backgroundLayer)
    outputLayer.addSublayer(videoLayer)
    outputLayer.addSublayer(overlayLayer)
    
    let videoComposition = AVMutableVideoComposition()
    videoComposition.renderSize = videoSize
    videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
    videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
      postProcessingAsVideoLayer: videoLayer,
      in: outputLayer)
    
    let instruction = AVMutableVideoCompositionInstruction()
    instruction.timeRange = CMTimeRange(
      start: .zero,
      duration: composition.duration)
    videoComposition.instructions = [instruction]
    let layerInstruction = compositionLayerInstruction(
      for: compositionTrack,
      assetTrack: assetTrack)
    instruction.layerInstructions = [layerInstruction]
    
    guard let export = AVAssetExportSession(
      asset: composition,
      presetName: AVAssetExportPresetHighestQuality ) //AVAssetExportPresetHighestQuality
      else {
        print("Cannot create export session.")
        onComplete(nil)
        return
    }
    
    let videoName = UUID().uuidString
    let exportURL = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent(videoName)
      .appendingPathExtension("mov")

    export.videoComposition = videoComposition
    export.outputFileType = .mov
    export.outputURL = exportURL
    
    export.exportAsynchronously {
      DispatchQueue.main.async {
        switch export.status {
        case .completed:
          onComplete(exportURL)
        default:
          print("Something went wrong during export.")
          print(export.error ?? "unknown error")
          onComplete(nil)
          break
        }
      }
    }
  }
  
  private func addImage(to layer: CALayer, videoSize: CGSize) {
    let image = UIImage(named: "overlay")!
    let imageLayer = CALayer()
    let aspect: CGFloat = image.size.width / image.size.height
    let width = videoSize.width
    let height = width / aspect
    imageLayer.frame = CGRect(
      x: 0,
      y: -height * 0.15,
      width: width,
      height: height)
    imageLayer.contents = image.cgImage
    layer.addSublayer(imageLayer)
  }
  
  private func add(text: String, to layer: CALayer, videoSize: CGSize) {
    let attributedText = NSAttributedString(
    string: text,
    attributes: [
      .font: UIFont(name: "ArialRoundedMTBold", size: 60) as Any,
      .foregroundColor: UIColor(named: "rw-green")!,
      .strokeColor: UIColor.white,
      .strokeWidth: -3])
    let mainY = videoSize.height * 0.66
    
    let textLayer = CATextLayer()
    textLayer.string = attributedText
    textLayer.shouldRasterize = true
    textLayer.rasterizationScale = UIScreen.main.scale
    textLayer.backgroundColor = UIColor.clear.cgColor
    textLayer.alignmentMode = .center
    
    textLayer.frame = CGRect(
      x: 0,
      y: mainY,
        width: videoSize.width,
      height: 150)
    textLayer.displayIfNeeded()
    
    let gradient = CAGradientLayer()
    let cor1 = UIColor.clear.cgColor
    let cor2 = UIColor.black.cgColor
    gradient.type = .axial
    gradient.colors = [cor1, cor2, cor2]
    gradient.startPoint = CGPoint(x: 0, y: 1)
    gradient.endPoint = CGPoint(x: 0.1, y: 1)
    gradient.frame = CGRect(
        x: textLayer.frame.origin.x,
          y: mainY,
          width: videoSize.width * 1.4,
          height: 150)
    gradient.displayIfNeeded()
    
    let textAnimation = CABasicAnimation(keyPath: "position")
    textAnimation.fromValue = [attributedText.width(containerHeight: 200)/2, mainY + attributedText.height(containerWidth: videoSize.width)]
    textAnimation.toValue = [attributedText.width(containerHeight: 200)*2, mainY + attributedText.height(containerWidth: videoSize.width)]
    textAnimation.duration = 6
//    scaleAnimation.repeatCount = 0
    textAnimation.autoreverses = true
    textAnimation.timingFunction = CAMediaTimingFunction(name: .default)
    textAnimation.beginTime = AVCoreAnimationBeginTimeAtZero + 0.25
    textAnimation.isRemovedOnCompletion = false
    gradient.add(textAnimation, forKey: "position1")
    
    let crewIconLayer = CALayer()
    let myImage = UIImage(named: "red-crew-icon")?.cgImage
//    let imageWidth = attributedText.height(containerWidth: 200)
    let w = myImage?.width
    let h = myImage?.height
    crewIconLayer.frame = CGRect(
        x: 0,
        y: Int(mainY),
        width: Int(Double(w!) * 1.1),
        height: Int(Double(h!) * 1.1) )
    crewIconLayer.contents = myImage
    
    let crewMoveAnimation = CABasicAnimation(keyPath: "position")
    crewMoveAnimation.fromValue = [ -crewIconLayer.frame.width, mainY + attributedText.height(containerWidth: videoSize.width)]
    crewMoveAnimation.toValue = [attributedText.width(containerHeight: 200)*2, mainY + attributedText.height(containerWidth: videoSize.width)]
    crewMoveAnimation.duration = 8
    crewMoveAnimation.autoreverses = true
    crewMoveAnimation.timingFunction = CAMediaTimingFunction(name: .default)
    crewMoveAnimation.beginTime = AVCoreAnimationBeginTimeAtZero
    crewMoveAnimation.isRemovedOnCompletion = false
    
    let crewRotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
    //clockwise
    crewRotationAnimation.toValue = NSNumber(value: -(Double.pi * 2))
    //anticlockwise
//    crewRotationAnimation.toValue = NSNumber(value: Double.pi * 2)
    crewRotationAnimation.isRemovedOnCompletion = false
    
    let groupAnimation = CAAnimationGroup()
    groupAnimation.beginTime = AVCoreAnimationBeginTimeAtZero
    groupAnimation.duration = 5
    groupAnimation.animations = [crewRotationAnimation, crewMoveAnimation]
    crewIconLayer.add(groupAnimation, forKey: "groupAnimation")
//    crewIconLayer.contentsGravity = CALayerContentsGravity.left
//    crewIconLayer.isGeometryFlipped = true

    
//    let scaleAnimation = CABasicAnimation(keyPath: "opacity")
//    scaleAnimation.beginTime = AVCoreAnimationBeginTimeAtZero
//    scaleAnimation.duration = 3.0
//    scaleAnimation.fromValue = 0
//    scaleAnimation.toValue = textLayer.bounds.size.width
// //    scaleAnimation.fillMode =
//    scaleAnimation.isRemovedOnCompletion = false
//    textLayer.add(scaleAnimation, forKey: "scale")
    
    
    let containerView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 375.0, height: 667.0))
//    XCPShowView("Container View", view: containerView)

    let rectangle = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 50.0, height: 50.0))
    rectangle.center = containerView.center
    rectangle.layer.cornerRadius = 5.0


    let tf:UITextField = UITextField(frame: containerView.bounds)
    tf.textColor = UIColor.white
    tf.text = "this is text"
    tf.textAlignment = NSTextAlignment.center;

    let gradientMaskLayer:CAGradientLayer = CAGradientLayer()
    gradientMaskLayer.frame = containerView.bounds
    gradientMaskLayer.colors = [UIColor.clear.cgColor, UIColor.red.cgColor, UIColor.red.cgColor, UIColor.clear.cgColor ]
    gradientMaskLayer.startPoint = CGPoint(x: 0.1, y: 0.0)
    gradientMaskLayer.endPoint = CGPoint(x: 0.55, y: 0.0)

    containerView.addSubview(tf)

//    tf.layer.mask = gradientMaskLayer
    
//    layer.mask = gradientMaskLayer
    layer.addSublayer(textLayer)
    layer.addSublayer(gradient)
    layer.addSublayer(crewIconLayer)
//    layer.insertSublayer(gradientMaskLayer, at: 0)
  }
  
  private func orientation(from transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
    var assetOrientation = UIImage.Orientation.up
    var isPortrait = false
    if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
      assetOrientation = .right
      isPortrait = true
    } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
      assetOrientation = .left
      isPortrait = true
    } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
      assetOrientation = .up
    } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
      assetOrientation = .down
    }
    
    return (assetOrientation, isPortrait)
  }
  
  private func compositionLayerInstruction(for track: AVCompositionTrack, assetTrack: AVAssetTrack) -> AVMutableVideoCompositionLayerInstruction {
    let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
    let transform = assetTrack.preferredTransform

    instruction.setTransform(transform, at: .zero)

    return instruction
  }
  
  private func addConfetti(to layer: CALayer) {
    let images: [UIImage] = (0...5).map { UIImage(named: "confetti\($0)")! }
    let colors: [UIColor] = [.systemGreen, .systemRed, .systemBlue, .systemPink, .systemOrange, .systemPurple, .systemYellow]
    let cells: [CAEmitterCell] = (0...16).map { i in
      let cell = CAEmitterCell()
      cell.contents = images.randomElement()?.cgImage
      cell.birthRate = 3
      cell.lifetime = 12
      cell.lifetimeRange = 0
      cell.velocity = CGFloat.random(in: 100...200)
      cell.velocityRange = 0
      cell.emissionLongitude = 0
      cell.emissionRange = 0.8
      cell.spin = 4
      cell.color = colors.randomElement()?.cgColor
      cell.scale = CGFloat.random(in: 0.2...0.8)
      return cell
    }
    
    let emitter = CAEmitterLayer()
    emitter.emitterPosition = CGPoint(x: layer.frame.size.width / 2, y: layer.frame.size.height + 5)
    emitter.emitterShape = .line
    emitter.emitterSize = CGSize(width: layer.frame.size.width, height: 2)
    emitter.emitterCells = cells
    
    layer.addSublayer(emitter)
  }
}

extension NSAttributedString {

    func height(containerWidth: CGFloat) -> CGFloat {

        let rect = self.boundingRect(with: CGSize.init(width: containerWidth, height: CGFloat.greatestFiniteMagnitude),
                                     options: [.usesLineFragmentOrigin, .usesFontLeading],
                                     context: nil)
        return ceil(rect.size.height)
    }

    func width(containerHeight: CGFloat) -> CGFloat {

        let rect = self.boundingRect(with: CGSize.init(width: CGFloat.greatestFiniteMagnitude, height: containerHeight),
                                     options: [.usesLineFragmentOrigin, .usesFontLeading],
                                     context: nil)
        return ceil(rect.size.width)
    }
}
