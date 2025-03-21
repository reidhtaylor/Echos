//
//  SpotifyPlaylist.swift
//  AM
//
//  Created by Reid Taylor on 8/9/24.
//

import SwiftUI

public func getRequest(_ url : String, authToken : String = "", onSuccess: @escaping ([String:Any]) -> Void = {v in }, onError: @escaping ((String, Int)) -> Void = { _ in }) {
    let reqUrl = URL(string: url)!
    var request = URLRequest(url: reqUrl)
    
    request.httpMethod = "GET"
    
    if authToken.count > 0 {
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "content-type")
        request.setValue("Bearer " + authToken, forHTTPHeaderField: "Authorization")
    }
    
    URLSession.shared.dataTask(with: request) { (data, response, error) in
        DispatchQueue.main.async {
            if let error = error as? URLError {
                // NETWORK ERROR
                var errStatus = -1
                switch error.code {
                    case .notConnectedToInternet: errStatus = 601
                    case .timedOut: errStatus = 602
                    case .cannotFindHost: errStatus = 603
                    default: errStatus = 600
                }
                print("- Spotify Request Error (\(errStatus))" + error.localizedDescription)
                onError((error.localizedDescription, errStatus))
                return
            }
            
            if let data = data {
                let dataString = String(data: data, encoding: .utf8)
                let jsonResult = try? JSONSerialization.jsonObject(with: Data(dataString!.utf8), options: JSONSerialization.ReadingOptions.mutableContainers) as? [String:Any]
                
                if jsonResult?.keys.contains("error") ?? false {
                    // SPOTIFY ERROR
                    let err = (jsonResult!["error"]! as! NSDictionary)
                    let errMsg = err["message"] as! String
                    let errStatus = err["status"] as! Int
                    
                    print("- Spotify Request Error (\(errStatus))")
                    onError((errMsg, errStatus))
                    return
                }
                
                onSuccess(jsonResult ?? [:])
                return
            }
        }
   }.resume()
}

struct SpotifyPlaylist : Equatable, Identifiable, Codable {
    
    var description : String? = nil
    var playlistID : String? = nil
    var playlistName : String? = nil
    var trackCount : Int? = nil
    var artworkURL : String? = nil
    
    public init(_ json : [String:Any]) {
        description = json["description"]! as? String
        playlistID = json["id"]! as? String
        playlistName = json["name"]! as? String
        trackCount = (json["tracks"]! as! NSDictionary)["total"]! as? Int
        artworkURL = ((json["images"]! as! NSArray)[0] as! NSDictionary)["url"]! as? String
    }
    
    static func == (lhs: SpotifyPlaylist, rhs: SpotifyPlaylist) -> Bool {
        return false
    }
    var id: String {
        playlistID!
    }
}

struct SpotifySong : Equatable, Identifiable, Codable {
    
    var songID : String = ""
    var name : String = ""
    var artistName : String = ""
    var albumName : String = ""
    var artworkURL : String = ""
    var popularity : Int = 0
    var trackNumber : Int = -1
    var duration : TimeInterval
    
    public init(_ json : [String:Any]) {
        let trackJson = (json["track"]! as! NSDictionary)
        self.songID = trackJson["id"] as! String
        self.name = trackJson["name"]! as! String
        self.artistName = ((trackJson["artists"] as! NSArray)[0] as! NSDictionary)["name"] as! String
        self.popularity = trackJson["popularity"] as! Int
        self.trackNumber = trackJson["track_number"] as! Int
        
        self.duration = TimeInterval(trackJson["duration_ms"] as! Int) / 1000
        
        let album = trackJson["album"] as! NSDictionary
        self.albumName = album["name"]! as! String
        self.artworkURL = ((album["images"]! as! NSArray)[0] as! NSDictionary)["url"] as! String
    }
    
    static func == (lhs: SpotifySong, rhs: SpotifySong) -> Bool {
        return lhs.songID == rhs.songID
    }
    var id: String {
        songID
    }
}

struct SpotifyArtist : Equatable, Identifiable, Codable {
    
    var artistID : String = ""
    var name : String = ""
    var artworkURL : String = ""
    
    public init(_ json : [String:Any]) {
        let artistJSON = json as NSDictionary
        self.artistID = artistJSON["id"]! as! String
        self.name = artistJSON["name"]! as! String
    }
    
    public mutating func loadImages(_ extraJSON : NSDictionary) {
        if extraJSON["images"] != nil && (extraJSON["images"] as! NSArray).count > 0 {
            self.artworkURL = ((extraJSON["images"] as! NSArray)[0] as! NSDictionary)["url"] as! String
        }
        else {
//            print(extraJSON)
        }
    }
    
    static func == (lhs: SpotifyArtist, rhs: SpotifyArtist) -> Bool {
        return lhs.id == rhs.id
    }
    var id: String {
        artistID
    }
}
//{
//    "external_urls" = {
//          spotify = "https://open.spotify.com/artist/107CG0UhUl9GJnPwF83N63";
//    };
//    href = "https://api.spotify.com/v1/artists/107CG0UhUl9GJnPwF83N63";
//    id = 107CG0UhUl9GJnPwF83N63;
//    name = UPPERROOM;
//    type = artist;
//    uri = "spotify:artist:107CG0UhUl9GJnPwF83N63";
//}


struct SpotifyAlbum : Equatable, Identifiable, Codable {
    
    var albumID : String = ""
    var name : String = ""
    var artworkURL : String = ""
    var artistName : String = ""
    
    public init(_ json : [String:Any]) {
        let albumJSON = json as NSDictionary
        self.albumID = albumJSON["id"]! as! String
        self.name = albumJSON["name"]! as! String
        
        if let albumArtists = albumJSON["artists"] as? NSArray {
            if albumArtists.count > 0 {
                if let artName = (albumArtists[0] as? NSDictionary)!["name"] as? String {
                    self.artistName = artName
                }
            }
        }
        
        if let albumImages = albumJSON["images"] as? NSArray {
            if albumImages.count > 0 {
                if let imageURL = (albumImages[0] as? NSDictionary)!["url"] as? String {
                    self.artworkURL = imageURL
                }
            }
        }
    }
    
    static func == (lhs: SpotifyAlbum, rhs: SpotifyAlbum) -> Bool {
        return lhs.id == rhs.id
    }
    var id: String {
        albumID
    }
}
//{
//    "album_type" = album;
//    artists =     (
//                {
//            "external_urls" =             {
//                spotify = "https://open.spotify.com/artist/04gDigrS5kc9YWfZHwBETP";
//            };
//            href = "https://api.spotify.com/v1/artists/04gDigrS5kc9YWfZHwBETP";
//            id = 04gDigrS5kc9YWfZHwBETP;
//            name = "Maroon 5";
//            type = artist;
//            uri = "spotify:artist:04gDigrS5kc9YWfZHwBETP";
//        }
//    );
//    "available_markets" =     (
//    );
//    "external_urls" =     {
//        spotify = "https://open.spotify.com/album/1pCA38N6MkLlthXtAOvZTU";
//    };
//    href = "https://api.spotify.com/v1/albums/1pCA38N6MkLlthXtAOvZTU";
//    id = 1pCA38N6MkLlthXtAOvZTU;
//    images =     (
//                {
//            height = 640;
//            url = "https://i.scdn.co/image/ab67616d0000b27386a8ab515de4b7aef28cd631";
//            width = 640;
//        },
//                {
//            height = 300;
//            url = "https://i.scdn.co/image/ab67616d00001e0286a8ab515de4b7aef28cd631";
//            width = 300;
//        },
//                {
//            height = 64;
//            url = "https://i.scdn.co/image/ab67616d0000485186a8ab515de4b7aef28cd631";
//            width = 64;
//        }
//    );
//    name = "JORDI (Deluxe)";
//    "release_date" = "2021-06-11";
//    "release_date_precision" = day;
//    "total_tracks" = 14;
//    type = album;
//    uri = "spotify:album:1pCA38N6MkLlthXtAOvZTU";
//}
