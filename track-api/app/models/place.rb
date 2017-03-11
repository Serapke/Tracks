class Place < ApplicationRecord
  belongs_to :song
  attribute :top_left, :legacy_point
  attribute :top_right, :legacy_point
  attribute :bottom_right, :legacy_point
  attribute :bottom_left, :legacy_point
end
