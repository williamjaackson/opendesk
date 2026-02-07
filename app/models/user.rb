class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :organisation_users, dependent: :destroy
  has_many :organisations, through: :organisation_users
  has_many :notifications, dependent: :destroy

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
