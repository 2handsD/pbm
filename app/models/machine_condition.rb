class MachineCondition < ApplicationRecord
  MAX_HISTORY_SIZE_TO_DISPLAY = 6

  belongs_to :user, optional: true
  belongs_to :location_machine_xref, optional: true
  has_one :location, through: :location_machine_xref
  has_one :machine, through: :location_machine_xref

  after_create :create_user_submission

  scope :limited, (-> { order('created_at DESC').limit(MachineCondition::MAX_HISTORY_SIZE_TO_DISPLAY) })

  def create_user_submission
    user_info = user ? user.username : 'UNKNOWN USER'

    UserSubmission.create(region_id: location.region_id, location: location, machine: machine, submission_type: UserSubmission::NEW_CONDITION_TYPE, submission: "#{user_info} commented on #{machine.name} at #{location.name}. They said: #{comment}", user: user)
  end

  def username
    user ? user.username : ''
  end

  def as_json(options = {})
    options[:methods] = [:username]
    super
  end
end
