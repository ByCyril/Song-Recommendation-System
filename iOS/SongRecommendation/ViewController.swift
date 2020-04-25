//
//  ViewController.swift
//  SongRecommendation
//
//  Created by Cyril Garcia on 4/21/20.
//  Copyright © 2020 Cyril Garcia. All rights reserved.
//

import UIKit
import CoreML


class ViewController: UITableViewController {
    
    var songs = [Song]()
    var recommendedSongs = [Song]()
    var markedSongs = [Song]()
    
    var model = SongRecKNN()
    
    private static let appDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    
    private var updatedModelURL = appDirectory.appendingPathComponent("SongRecKNN.mlmodelc")
    private var tempUpdatedModelURL = appDirectory.appendingPathComponent("SongRecKNN_tc.mlmodelc")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if markedSongs.isEmpty {
            guard FileManager.default.fileExists(atPath: updatedModelURL.path) else { return }
            guard let model = try? SongRecKNN(contentsOf: updatedModelURL) else { return }
            
            self.model = model
            updateTableView()
        } else {
            prepareModel()
        }
    }
    
    func prepareModel() {
        let modelUrl = Bundle(for: SongRecKNN.self).url(forResource: "SongRecKNN", withExtension: "mlmodelc")!
        
        let data = prepareData()
        let config = MLModelConfiguration()
        config.allowLowPrecisionAccumulationOnGPU = true
        
        do {
            let updateTask = try MLUpdateTask(forModelAt: modelUrl, trainingData: data, configuration: config, completionHandler: { [weak self] (context) in
                
                let updatedModel = context.model
                let fileManager = FileManager.default
                self?.model.model = context.model
                
                do {
                    try fileManager.createDirectory(at: self!.tempUpdatedModelURL, withIntermediateDirectories: true, attributes: nil)
                    
                    try updatedModel.write(to: self!.tempUpdatedModelURL)
                    
                    _ = try fileManager.replaceItemAt(self!.updatedModelURL, withItemAt: self!.tempUpdatedModelURL)
                    
                } catch {
                    print("error here",error.localizedDescription)
                }
                
                self?.updateTableView()
                self?.markedSongs.removeAll()
            })
            
            updateTask.resume()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func prepareData() -> MLArrayBatchProvider {
        var featureProvider = [MLFeatureProvider]()
        
        for song in markedSongs {
            let singleTrainingData = SongRecKNNTrainingInput(song: song.vec(), prob: "\(song.score)")
            featureProvider.append(singleTrainingData)
        }
        
        let trainingData = MLArrayBatchProvider(array: featureProvider)
        return trainingData
        
    }
    
    func predict(_ input: MLMultiArray) -> Double {
        do {
            let prediction = try model.prediction(song: input)
            return prediction.probProbs["1.0"] ?? 0.0
        } catch {
            print(error.localizedDescription)
            return 0.0
        }
        
    }
    
    func updateTableView() {
        
        for song in songs {
            var newSong = song
            let score = predict(song.vec())
            if score >= 0.5 {
                newSong.score = predict(song.vec())
                recommendedSongs.append(newSong)
            }
        }
        
        recommendedSongs.sort { (s1, s2) -> Bool in
            return s1.score > s2.score
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
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
        
        let byScore = UIAlertAction(title: "Score", style: .default) { (_) in
            self.sort(by: .score)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(byTitle)
        alert.addAction(byArtist)
        alert.addAction(byScore)
        alert.addAction(cancel)
        
        present(alert, animated: true, completion: nil)
    }
    
    func sort(by category: Category) {
        recommendedSongs.sort { (s1, s2) -> Bool in
            switch category {
            case .artist:
                return s1.artist < s2.artist
            case .title:
                return s1.title < s2.title
            case .score:
                return s1.score > s2.score
            }
        }
        
        tableView.reloadData()
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recommendedSongs.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomCell
        let song = recommendedSongs[indexPath.row]
        
        cell.songTitle.text = song.title
        cell.artistLabel.text = song.artist + " | " + song.genre
        cell.scoreLabel.text = "\(song.score)"
        
        return cell
    }
    
}

class CustomCell: UITableViewCell {
    @IBOutlet var songTitle: UILabel!
    @IBOutlet var artistLabel: UILabel!
    @IBOutlet var scoreLabel: UILabel!
}
