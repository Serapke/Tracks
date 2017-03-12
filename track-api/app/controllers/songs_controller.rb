class SongsController < ApplicationController
  before_action :set_song, only: [:create]
  before_action :authenticate_with_token!, only: [:index, :create, :get_song]

  def index
    @songs = current_user.songs.all
    render json: @songs, include: :places, except: [:created_at, :updated_at]
  end

  def create
    @new_song = current_user.songs.build(song_params)
    if @song && same_song(@new_song, @song)
      puts "Add new location"
      add_new_location_to_song(@song)
    else
      add_new_song(@new_song)
    end
  end

  def get_song
    location = params[:location][1..-2].split(',').collect! {|n| n.to_d}
    songs = current_user.songs
    found = false
    songs.each do |song|
      places = song.places
      places.each do |place|
        if contains(place, location)
          song = Song.find(place.song_id)
          found = true
          render json: song, include: {places: {:except => [:song_id, :created_at, :updated_at]}}
          break
        end
      end
      if found
        break
      end
    end
    unless found
      render json: { errors: "No song in this location" } , status: 200
    end
  end

  private

  def set_song
    @song = Song.where(spotify_id: params[:song][:spotify_id]).first
  end

  def song_params
    params.require(:song).permit(:spotify_id)
  end

  def place_params
    params.require(:place).permit(top_left: [], top_right: [], bottom_right: [], bottom_left: [])
  end

  def same_song(song1, song2)
    song1.spotify_id.equal?(song2.spotify_id)
  end

  def add_new_location_to_song(song)
    place = song.places.build(place_params)
    add_location(place)
  end

  def add_new_song(song)
    if song.save
      place = song.places.build(place_params)
      add_location(song, place)
    else
      render json: @new_song.errors , status: 422
    end
  end

  def add_location(song, place)
    if place.save
      render json: { "song": song, "place": place }, status: 201
    else
      render json: place.errors , status: 422
    end
  end

  def contains(place, location)
    polygon = Geokit::Polygon.new([
                                      Geokit::LatLng.new(place.top_left[0], place.top_left[1]),
                                      Geokit::LatLng.new(place.top_right[0], place.top_right[1]),
                                      Geokit::LatLng.new(place.bottom_right[0], place.bottom_right[1]),
                                      Geokit::LatLng.new(place.bottom_left[0], place.bottom_left[1])
                                  ])
    point = Geokit::LatLng.new(location[0].to_d, location[1].to_d)
    polygon.contains?(point)
  end
end
