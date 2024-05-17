import spotipy 
from spotipy.oauth2 import SpotifyClientCredentials
import spotipy.util as util
from spotipy.oauth2 import SpotifyOAuth
import random
import pandas as pd
import torch
import torch.nn as nn
import torch.nn.functional as F
import tkinter
import subprocess


import tkinter as tk

cid = "insert cid here"
secret = "insert secret here"
redirect_uri = 'http://127.0.0.1'
scope = 'user-read-currently-playing'
username = "antti.meriluoto"

filepath = "send_data.txt"

token = util.prompt_for_user_token(username, scope,
                                   cid, secret,
                                   redirect_uri='http://localhost:8888/callback')
spotify = spotipy.Spotify(auth=token)

def extract_features_from_uri(uri):
    features = spotify.audio_features(uri)[0]
    #print(features)
    features_lst = [ features["energy"],
                    #features["tempo"] / 200,
                    features["valence"]
                    #features["mode"]
                    #features["key"] / 10
                    ]
    
    return torch.tensor(features_lst)

def get_current_song():
    # Get track information
    track = spotify.current_user_playing_track()
    #pprint(track)
    artist = track["item"]["artists"][0]["name"]
    t_name = track["item"]["name"]
    t_id = track["item"]["id"]
    uri = track["item"]["uri"]
    features = extract_features_from_uri(uri)

    #print(features)

    return artist, t_name, t_id, torch.tensor(features)



class NeuralNetwork(nn.Module):
    def __init__(self):
        super(NeuralNetwork, self).__init__()
        self.fc1 = nn.Linear(2, 10)
        self.fc2 = nn.Linear(10, 3)

    def forward(self, x):
        x = F.relu(self.fc1(x))    # Pass input through first hidden layer and activation function
        x = self.fc2(x)
        #return torch.sigmoid(x)
        return F.softmax(x)
    
model = NeuralNetwork()
model.load_state_dict(torch.load('model2.pth'))

# Put the model in evaluation mode
model.eval()

class MusicPlayerGUI:
    def __init__(self, master):
        self.master = master
        self.current_song = "No song playing"

        self.label_song = tk.Label(master, text=self.current_song)
        self.label_song.pack()

        #self.button_send = tk.Button(master, text="Send Data", command=self.send_data)
        #self.button_send.pack()

        self.button_change_song = tk.Button(master, text="Change Song", command=self.change_song)
        self.button_change_song.pack()
        self.features = None

    def send_data(self, features):
        pred = model(features)
        mood = torch.argmax(pred)
        data = str(features[0].item()) + "," + str(mood.item())
        user = "root"
        remote_host = "10.253.17.34"
        remote_path = "/home/root/final-combined/" + filepath

        print(mood.item())
        with open(filepath, 'w') as file:
            file.write(data)
        
        file.close()
        scp_command = f"scp {filepath} {user}@{remote_host}:{remote_path}"
        subprocess.run(scp_command, shell=True)

    def change_song(self):
        artist, title, _, features = get_current_song()

        self.current_song = title + " - " + artist
        self.label_song.config(text=self.current_song)
        print("Song changed to:", self.current_song)
        self.send_data(features)

def main():
    root = tk.Tk()
    root.title("Music Player")
    app = MusicPlayerGUI(root)
    root.mainloop()

if __name__ == "__main__":
    main()






