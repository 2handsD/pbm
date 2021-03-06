class LocationMachineXref < ApplicationRecord
  include Rakismet::Model

  rakismet_attrs content: :condition

  belongs_to :location, optional: true
  belongs_to :machine, optional: true
  belongs_to :user, optional: true
  has_many :machine_score_xrefs
  has_many :machine_conditions, (-> { order 'created_at desc' })

  after_create :update_location, :create_user_submission

  scope :region, (lambda { |name|
    r = Region.find_by_name(name.downcase)

    return unless r

    joins(:location).where('locations.region_id = ?', r.id)
  })

  def haml_object_ref
    'lmx'
  end

  def add_host_info_to_subject(subject, host)
    server_name = host&.match?(/pinballmapstaging/) ? '(STAGING) ' : ''

    server_name + subject
  end

  def update_condition(condition, options = {})
    return if condition == self.condition
    return if condition.blank?

    self.condition = condition
    self.condition_date = Date.today
    self.user_id = options[:user_id]

    location.date_last_updated = Date.today
    location.last_updated_by_user_id = options[:user_id]
    location.save(validate: false)

    save

    MachineCondition.create(comment: condition, location_machine_xref: self, user_id: location.last_updated_by_user_id)

    return if condition.nil? || condition.blank? || location.region_id.blank?

    user_info = location.last_updated_by_user ? " by #{location.last_updated_by_user.username} (#{location.last_updated_by_user.email})" : ''

    unless location.region&.send_digest_comment_emails?
      Pony.mail(
        to: location.region.users.map(&:email),
        from: 'admin@pinballmap.com',
        subject: add_host_info_to_subject('PBM - Someone entered a machine condition', options[:request_host]),
        body: [condition, machine.name, location.name, location.region.name, "(entered from #{options[:remote_ip]} via #{options[:user_agent]}#{user_info})"].join("\n")
      )
    end
  end

  def as_json(options = {})
    h = super(options)
    h[:machine_conditions] = machine_conditions.first(MachineCondition::MAX_HISTORY_SIZE_TO_DISPLAY)

    h
  end

  def sorted_machine_conditions
    # Offset by 1 so that we don't show the current machine condition
    machine_conditions.limited.offset(1)
  end

  def update_location
    location.date_last_updated = Date.today
    location.save(validate: false)
  end

  def destroy(options = {})
    if location.region&.should_email_machine_removal && !location.region&.send_digest_removal_emails
      user_info = nil
      if options[:user_id]
        user = User.find(options[:user_id])
        user_info = " by #{user.username} (#{user.email})"
      end

      Pony.mail(
        to: location.region.users.map(&:email),
        from: 'admin@pinballmap.com',
        subject: add_host_info_to_subject('PBM - Someone removed a machine from a location', options[:request_host]),
        body: [location.name, machine.name, location.region.name, "(user_id: #{options[:user_id]}) (entered from #{options[:remote_ip]} via #{options[:user_agent]}#{user_info})"].join("\n")
      )
    end

    user = nil
    user = User.find(options[:user_id]) if options[:user_id]

    UserSubmission.create(region_id: location.region_id, location: location, machine: machine, submission_type: UserSubmission::REMOVE_MACHINE_TYPE, submission: "#{machine.name} was removed from #{location.name}#{user.nil? ? '' : ' by ' + user.name}", user: user)

    location.date_last_updated = Date.today
    location.last_updated_by_user_id = user.nil? ? nil : user.id
    location.save(validate: false)
    location

    super()
  end

  def create_user_submission
    UserSubmission.create(region_id: location.region_id, location: location, machine: machine, submission_type: UserSubmission::NEW_LMX_TYPE, submission: "#{machine.name} was added to #{location.name}#{user.nil? ? '' : ' by ' + user.name}", user: user)
  end

  def current_condition
    machine_conditions.first
  end

  def last_updated_by_username
    user ? user.username : ''
  end
end
