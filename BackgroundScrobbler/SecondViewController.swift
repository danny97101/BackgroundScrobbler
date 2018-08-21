//
//  SecondViewController.swift
//  BackgroundScrobbler
//
//  Created by Daniel Akimchuk on 8/20/18.
//  Copyright © 2018 okdanny. All rights reserved.
//

import UIKit
import MediaPlayer
import Alamofire
import UserNotifications

class SecondViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var scrobblingStatus: UITextView!
    @IBOutlet weak var trackName: UILabel!
    @IBOutlet weak var artistAlbum: UILabel!
    var info: [String:Any] = [:]
    var previousTrack = ""
    var previousArtist = ""
    var previousAlbum = ""
    var previousTS = TimeInterval()
    var previousScrobbleTime = TimeInterval()
    var notification = UNMutableNotificationContent()
    let center = UNUserNotificationCenter.current()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        backgroundForever()
    }
    
    func backgroundForever() {
        let application = UIApplication.shared
        var bgTask: UIBackgroundTaskIdentifier = 0;
        bgTask = application.beginBackgroundTask()
        print("beginning background task: " + String(NSDate().timeIntervalSince1970))
        let now = NSDate().timeIntervalSince1970
        let info = self.getNowPlaying()
        if info.count > 0 {
            let track = info["track"] as! String
            let artist = info["artist"] as! String
            let album = info["album"] as! String
            let ts = info["playbackTime"] as! TimeInterval
            let duration = info["duration"] as! TimeInterval
            let albumArtist = info["albumArtist"] as! String
            let trackNumber = info["trackNumber"] as! Int
            let halfway = duration/2
            
            if track == previousTrack && artist == previousArtist && album == previousAlbum && halfway < ts && now - previousScrobbleTime > halfway {
                print("scrobbling " + track)
                scrobble(track: track, artist: artist, album: album, albumArtist: albumArtist, trackNumber: trackNumber, duration: duration)
                previousScrobbleTime = now
            }
            
            previousTrack = track
            previousArtist = artist
            previousAlbum = album
            previousTS = ts
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(15), execute: {
                self.backgroundForever()
                application.endBackgroundTask(bgTask)
            })
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(20), execute: {
                self.backgroundForever()
                application.endBackgroundTask(bgTask)
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func scrobble(track: String!, artist: String!, album: String!, albumArtist: String!, trackNumber: Int!, duration: TimeInterval!) {
        let key = UserDefaults.standard.string(forKey: "last.fm key")!
        let ts = Int(NSDate().timeIntervalSince1970.rounded())
        let durationStr = Int(duration.rounded())
        var sigString = "album" + album!
        sigString += "albumArtist" + albumArtist!
        sigString += "api_key" + "30de5967bb20f2e96bd7a7514a6205ac"
        sigString += "artist" + artist!
        sigString += "duration" + String(durationStr)
        sigString += "method" + "track.scrobble"
        sigString += "sk" + key
        sigString += "timestamp" + String(ts)
        sigString += "track" + track!
        sigString += "trackNumber" + String(trackNumber)
        sigString += "4611dc9dbbfe3f7cb20e0cc8c5ca65c1"
        
        let sig = md5(sigString)
        
        
        let parameters: [String:Any] = [
            "album": album!,
            "albumArtist": albumArtist!,
            "api_key": "30de5967bb20f2e96bd7a7514a6205ac",
            "api_sig": sig,
            "artist": artist!,
            "duration": durationStr,
            "method": "track.scrobble",
            "sk": key,
            "timestamp": ts,
            "track": track!,
            "trackNumber": trackNumber!
        ]
        
        Alamofire.request("https://ws.audioscrobbler.com/2.0/", method: HTTPMethod.post, parameters: parameters, encoding: URLEncoding.default).responseData { response in
        }
        scrobblingStatus.text = "Scrobbled!"
        scrobblingStatus.textColor = UIColor.green
        
    }
    
    func getNowPlaying() -> [String:Any] {
        let defaults = UserDefaults.standard
        let controller = MPMusicPlayerController.systemMusicPlayer
        var info: [String: Any] = [:]
        if controller.playbackState == MPMusicPlaybackState.playing {
            info["track"] = controller.nowPlayingItem!.title!
            info["artist"] = controller.nowPlayingItem!.artist!
            info["album"] = controller.nowPlayingItem!.albumTitle!
            info["duration"] = controller.nowPlayingItem!.playbackDuration
            info["playbackTime"] = controller.currentPlaybackTime
            info["albumArtist"] = controller.nowPlayingItem!.albumArtist
            info["trackNumber"] = controller.nowPlayingItem!.albumTrackNumber

            if info["track"] as! String != previousTrack || info["artist"] as! String != previousArtist || info["album"] as! String != previousAlbum {
                notification = UNMutableNotificationContent()
                notification.title = info["track"] as! String
                notification.body = (info["artist"] as! String) + " –– " + (info["album"] as! String)
                notification.sound = nil
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
                let request = UNNotificationRequest(identifier: "Now Playing", content: notification, trigger: trigger)
                center.add(request, withCompletionHandler: { (error) in
                    if let error = error {
                        print("Couldn't post notification.")
                    }
                })
                
                trackName.text = (info["track"] as! String)
                artistAlbum.text = notification.body
                imageView.image = controller.nowPlayingItem!.artwork?.image(at: CGSize(width: 500, height: 500))
                scrobblingStatus.text = "Scrobbling..."
                scrobblingStatus.textColor = UIColor.blue

                var sigString = "album" + (info["album"] as! String)
                sigString += "api_key" + "30de5967bb20f2e96bd7a7514a6205ac"
                sigString += "artist" + (info["artist"] as! String)
                sigString += "method" + "track.updateNowPlaying"
                sigString += "sk" + defaults.string(forKey: "last.fm key")!
                sigString += "track" + (info["track"] as! String)
                sigString += "4611dc9dbbfe3f7cb20e0cc8c5ca65c1"

                
                let sig = md5(sigString)
                
                let parameters: [String:Any] = [
                    "artist": info["artist"]!,
                    "album": info["album"]!,
                    "api_key": "30de5967bb20f2e96bd7a7514a6205ac",
                    "api_sig": sig,
                    "method": "track.updateNowPlaying",
                    "sk": defaults.string(forKey: "last.fm key")!,
                    "track": info["track"]!
                ]

                Alamofire.request("https://ws.audioscrobbler.com/2.0/", method: HTTPMethod.post, parameters: parameters, encoding: URLEncoding.default).responseData { response in
                }
            }
        }
        return info
    }
    
    @objc func md5(_ string: String) -> String {
        
        let context = UnsafeMutablePointer<CC_MD5_CTX>.allocate(capacity: 1)
        var digest = Array<UInt8>(repeating:0, count:Int(CC_MD5_DIGEST_LENGTH))
        CC_MD5_Init(context)
        CC_MD5_Update(context, string, CC_LONG(string.lengthOfBytes(using: String.Encoding.utf8)))
        CC_MD5_Final(&digest, context)
        context.deallocate()
        var hexString = ""
        for byte in digest {
            hexString += String(format:"%02x", byte)
        }
        
        return hexString
    }


}

