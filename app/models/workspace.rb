# frozen_string_literal: true

# == Schema Information
#
# Table name: workspaces
#
#  id           :bigint           not null, primary key
#  api_key      :string
#  name         :string
#  slug         :string
#  status       :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class Workspace < ApplicationRecord
  has_many :workspace_users, dependent: :nullify
  has_many :users, through: :workspace_users
  has_many :connectors, dependent: :nullify
  has_many :models, dependent: :nullify
  has_many :catalogs, dependent: :nullify
  has_many :syncs, dependent: :nullify
  belongs_to :organization

  STATUS_ACTIVE = "active"
  STATUS_INACTIVE = "inactive"
  STATUS_PENDING = "pending"

  validates :name, presence: true
  validates :slug, presence: true
  validates :status, inclusion: { in: [STATUS_ACTIVE, STATUS_INACTIVE, STATUS_PENDING] }

  before_validation :generate_slug_and_status, on: :create
  before_update :update_slug, if: :name_changed?

  private

  def generate_slug_and_status
    self.slug ||= name.parameterize if name
    self.api_key ||= SecureRandom.hex(32)
    self.status ||= STATUS_PENDING
  end

  def update_slug
    self.slug = name.parameterize if name.present?
  end
end
