class User < ApplicationRecord
  has_secure_password

  ROLES = %w[admin supervisor technician].freeze

  before_validation :normalize_email

  validates :email, presence: true,
                   uniqueness: { case_sensitive: false },
                   length: { maximum: 255 },
                   format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :role, presence: true, inclusion: { in: ROLES }

  scope :active, -> { where(active: true) }

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
