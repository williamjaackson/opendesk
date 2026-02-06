class OrganisationInvite < ApplicationRecord
  belongs_to :organisation

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: { scope: :organisation_id, conditions: -> { pending }, message: "has already been invited" }
  validates :token, presence: true, uniqueness: true

  before_validation :generate_token, on: :create

  normalizes :email, with: ->(e) { e.strip.downcase }

  scope :pending, -> { where(accepted_at: nil) }

  def pending?
    accepted_at.nil?
  end

  def accepted?
    accepted_at.present?
  end

  def accept!(user)
    return false if accepted?
    return false if organisation.users.include?(user)

    transaction do
      organisation.users << user
      update!(accepted_at: Time.current)
    end
    true
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end
end
