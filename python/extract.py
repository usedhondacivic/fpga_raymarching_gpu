import spotipy 
from spotipy.oauth2 import SpotifyClientCredentials
import spotipy.util as util
import random
import pandas as pd
import torch


cid = "insert cid here"
secret = "insert secret here"

scope = 'user-read-currently-playing'
username = "antti.meriluoto"

token = util.prompt_for_user_token(username, scope,
                                   cid, secret,
                                   redirect_uri='http://localhost:8888/callback')
sp = spotipy.Spotify(auth=token)

def get_playlist_tracks(uri):
    results = sp.playlist_tracks(playlist_URI)
    tracks = results["items"]
    while results['next']:
        results = sp.next(results)
        tracks.extend(results['items'])
    return tracks

def generate_csv_from_playlist(uri, csv_file_name):
    tracks = get_playlist_tracks(uri)

    song_data = [(track["track"]["name"], track["track"]["artists"][0]["name"], track["track"]["uri"], get_str_from_uri(track["track"]["uri"])) for track in tracks]
    df = pd.DataFrame(song_data, columns=['Song Name', 'Artist', 'URI', 'Features'])
    df.to_excel(csv_file_name, index=False)

def extract_song_data(input_file):
    # Read the Excel file
    df = pd.read_excel(input_file)
    
    # Extract song data into a list of tuples
    song_data = []
    for index, row in df.iterrows():
        song_name = row['Song Name']
        url = row['URI']
        emotion = row['Mood']
        song_data.append((song_name, url, emotion))
        #features = extract_features_from_uri(url)

        #if index == 10:
        #    print(features)
        #    exit()
    return song_data


def extract_features_from_uris(uris):
    features = sp.audio_features(uris)

    tensor_lst = []
    for x in features:
        features_lst = [ x["energy"],
                    x["tempo"] / 200,
                    x["valence"],
                    x["mode"],
                    x["key"] / 10]
        
        tensor_lst.append(torch.tensor(features_lst))
    
    return tensor_lst



def get_str_from_uri(uri):
    features = sp.audio_features(uri)[0]
    #print(features)
    features_lst = [ features["energy"],
                    features["danceability"],
                    features["valence"],
                    features["mode"], 
                    features["loudness"]
                    ]
    
    return ','.join([str(elem) for elem in features_lst])

def extract_features_from_uri(uri):
    features = sp.audio_features(uri)[0]
    #print(features)
    features_lst = [ features["energy"],
                    #features["tempo"] / 200,
                    features["valence"]
                    #features["mode"]
                    #features["key"] / 10
                    ]
    
    return torch.tensor(features_lst)



def get_dataset_from_spreadsheet(sheetname):
    df = pd.read_excel(sheetname)

    data = []
    for index, row in df.iterrows():
        feature_str = row["Features"]
        mood_str = row["Mood"]

        feature_lst = feature_str.split(",")
        #features = [float(x) for x in feature_lst[0:3]]
        features = [float(feature_lst[0]), float(feature_lst[2])]

        #mood = [float(mood_str=="Happy" or mood_str == "Neutral")]

        mood = [float(mood_str == "Positive"),
                #float(mood_str == "Neutral"),
                float(mood_str == "Angry"), 
                float(mood_str == "Sad")]        
        data.append((torch.tensor(features), torch.tensor(mood)))
    
    return data

def get_current_song():
    # Get track information
    track = sp.current_user_playing_track()
    #pprint(track)
    artist = track["item"]["artists"][0]["name"]
    t_name = track["item"]["name"]
    t_id = track["item"]["id"]
    uri = track["item"]["uri"]
    features = extract_features_from_uri(uri)

    #print(features)

    return artist, t_name, t_id, torch.tensor(features)


playlist_link = "https://open.spotify.com/playlist/0MNvysmJiIcADPvy66CRoe?si=73bbec784f114efb"
playlist_URI = playlist_link.split("/")[-1].split("?")[0]
