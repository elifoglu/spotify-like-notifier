#!/bin/bash

# https://developer.spotify.com/ to get an access token that lasts an hour

spotify_access_token='YOUR_SPOTIFY_ACCESS_TOKEN'

get_all_playlists () { 
   curl --request GET \
  --url https://api.spotify.com/v1/me/playlists\?limit\=50\&offset\=$1 \
  --header 'Authorization: Bearer '"$spotify_access_token"
}

get_playlist_data () {
   curl --silent --request GET \
  --url https://api.spotify.com/v1/playlists/$1?market=TR \
  --header 'Authorization: Bearer '"$spotify_access_token"
}

mkdir -p playlists

# multiple requests had to be sent by changing the offset value, since the "limit" value cannot be bigger than 50 
get_all_playlists 0 | jq '.items | .[] | .uri' > first_50.txt
get_all_playlists 50 | jq '.items | .[] | .uri' > second_50.txt
get_all_playlists 100 | jq '.items | .[] | .uri' > third_50.txt
get_all_playlists 150 | jq '.items | .[] | .uri' > fourth_50.txt
cat first_50.txt second_50.txt third_50.txt fourth_50.txt | cut -c 19- | cut -c -22 > all_playlist_ids.txt

while read playlist_id; do
  get_playlist_data $playlist_id | jq '.name, .followers.total' > playlist_name_and_like_count_data.txt
  playlist_name=$(head -n 1 playlist_name_and_like_count_data.txt)
  playlist_name="${playlist_name#?}" # removes first character, which is a quote
  playlist_name="${playlist_name%?}" # removes last character, which is a quote
  
  echo $playlist_name > temp.txt
  playlist_name=$(tr -d '/' < temp.txt)  # removes all forwards lashes in playlist names since the file cannot be created when filename contains some forward slashes 
  echo $playlist_name > temp.txt
  playlist_name=$(tr -d ' ' < temp.txt)  # removes all spaces in playlist names

  like_count=$(tail -n 1 playlist_name_and_like_count_data.txt)

  prev_like_count=$(head -n 1 playlists/$playlist_name) # to be able to compare like counts, firstly get the previous like count before overriding the file 

  if [ "$like_count" != "$prev_like_count" ]; then # print if like count of a playlist changed
          echo $playlist_name $prev_like_count $like_count
  fi

  echo $like_count > playlists/$playlist_name #save current like count to the related playlist file

done <all_playlist_ids.txt

rm first_50.txt second_50.txt third_50.txt fourth_50.txt playlist_name_and_like_count_data.txt temp.txt
