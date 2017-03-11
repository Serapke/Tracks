class Song < ApplicationRecord
  has_many :places

  validates :spotify_id, { uniqueness: true, presence: true }
end
