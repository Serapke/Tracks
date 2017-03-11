class Song < ApplicationRecord
  has_many :places
  belongs_to :user

  validates :spotify_id, { uniqueness: true, presence: true }
end
