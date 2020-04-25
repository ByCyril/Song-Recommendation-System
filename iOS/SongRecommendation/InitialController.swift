//
//  InitialController.swift
//  SongRecommendation
//
//  Created by Cyril Garcia on 4/21/20.
//  Copyright © 2020 Cyril Garcia. All rights reserved.
//

import UIKit
import CoreML

struct Song: Hashable {
    var id: Int
    var title: String
    var artist: String
    var genre: String
    var bpm: Double
    var energy: Double
    var dance: Double
    var live: Double
    var valence: Double
    var duration: Double
    var acousticness: Double
    var speech: Double
    var popularity: Double
    var score: Double = 0.0
    var genre_code: Double
    var artist_code: Double
    
    func vec() -> MLMultiArray {
        return try! MLMultiArray([bpm, energy, dance, live, valence, duration, acousticness, speech, popularity, genre_code, artist_code])
    }
}

enum Preference {
    case like
    case dislike
}

enum Category {
    case title
    case artist
    case score
}

final class InitialController: UITableViewController {
    
    var likeCount = 0
    var dislikeCount = 0
    
    var songs = [Song]()
    var markedSongs = [Song]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Home"
        retrieveSongList()
    }
    
    func retrieveSongList() {
        guard let path = Bundle.main.path(forResource: "data", ofType: "csv") else { return }
        
        let url = URL(fileURLWithPath: path)
        var i = 0
        do {
            let data = try Data(contentsOf: url)
            let dataEncoded = String(data: data, encoding: .utf8)
            if  let dataArr = dataEncoded?.components(separatedBy: "\r\n").map({ $0.components(separatedBy: ",") }) {
                for line in dataArr {
                    if i == 0 || line.count <= 1 {
                        i += 2
                        continue
                    }
                    let id = Int(line[0])!
                    let title = line[1]
                    let artist = line[2]
                    let genre = line[3]
                    let bpm = Double(line[4])!
                    let energy = Double(line[5])!
                    let dnc = Double(line[6])!
                    let live = Double(line[7])!
                    let val = Double(line[8])!
                    let dur = Double(line[9])!
                    let acous = Double(line[10])!
                    let spch = Double(line[11])!
                    let pop = Double(line[12])!
                    let artist_code = Double(line[13])!
                    let genre_code = Double(line[14])!
                    
                    let song = Song(id: id, title: title, artist: artist, genre: genre, bpm: bpm, energy: energy, dance: dnc, live: live, valence: val, duration: dur, acousticness: acous, speech: spch, popularity: pop, genre_code: genre_code, artist_code: artist_code)
                    
                    songs.append(song)
                    
                }
                tableView.reloadData()
            }
            
        } catch {
            print(error.localizedDescription)
        }
        
    }
    
    @IBAction func sortPrompt() {
        let alert = UIAlertController(title: "Sort by", message: "", preferredStyle: .actionSheet)
        let byTitle = UIAlertAction(title: "Title", style: .default) { (_) in
            self.sort(by: .title)
        }
        
        let byArtist = UIAlertAction(title: "Artist", style: .default) { (_) in
            self.sort(by: .artist)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(byTitle)
        alert.addAction(byArtist)
        alert.addAction(cancel)
        
        present(alert, animated: true, completion: nil)
    }
    
    func sort(by category: Category) {
        songs.sort { (s1, s2) -> Bool in
            return category == .title ? s1.title < s2.title : s1.artist < s2.artist
        }
        
        tableView.reloadData()
    }
    
    func markSong(at indexPath: IndexPath, as pref: Preference) {
        var song = songs[indexPath.row]
        
        song.score = (pref == .like) ? 1.0 : 0.0
        markedSongs.append(song)
        
        songs.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: (pref == .like) ? .right : .left)
        
        if pref == .like {
            likeCount += 1
        } else {
            dislikeCount += 1
        }
        
        updateTitle()
    }
    
    func updateTitle() {
        self.title = "# Dislikes: \(dislikeCount) - # Likes: \(likeCount)"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "send" {
            self.title = "Home"
            let vc = segue.destination as! ViewController
            vc.songs = songs
            vc.markedSongs = markedSongs
            markedSongs.removeAll()
        }
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .normal, title: "Like") { (action, view, success) in
            self.markSong(at: indexPath, as: .like)
            success(true)
        }
        return UISwipeActionsConfiguration(actions: [action])
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .normal, title: "Dislike") { (action, view, success) in
            self.markSong(at: indexPath, as: .dislike)
            success(true)
        }
        return UISwipeActionsConfiguration(actions: [action])
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let song = songs[indexPath.row]
        
        cell.textLabel?.text = song.title
        cell.detailTextLabel?.text = song.artist
        
        return cell
    }
}
