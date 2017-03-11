class SongsController < ApplicationController
  before_action :set_song, only: []

  def index
    @songs = Song.all
    render json: @songs
  end

  def create
    @song = Song.new(song_params)
    if @song.save
      place = @song.places.build(place_params)
      if place.save
        render json: @song.places, status: 201
      else
        render json: place.errors , status: 422
      end
    else
      render json: @song.errors , status: 422
    end
  end

  def get_song
  end

  private

  def set_song
    @song = Song.find(params[:id])
  end

  def song_params
    params.require(:song).permit(:spotify_id)
  end

  def place_params
    params.require(:place).permit(top_left: [], top_right: [], bottom_right: [], bottom_left: [])
  end

end
