class Location < ActiveRecord::Base
  include Rakismet::Model

  rakismet_attrs :content => :description

  validates_presence_of :name, :street, :city, :state, :zip
  validates :phone, format: { with: /\d{3}-\d{3}-\d{4}/, message: "format invalid, please use ###-###-####" }, :if => :phone?
  validates :website, format: { with: /^http:\/\//, message: "must begin with http://" }, :if => :website?
  validates :name, :street, :city, :state, format: { with: /^\S.*/, message: "Can't start with a blank" }
  validates :lat, :lon, :presence => {:message => "Latitude/Longitude failed to generate. Please double check address and try again, or manually enter the lat/lon" }

  belongs_to :location_type
  belongs_to :zone
  belongs_to :region
  belongs_to :operator
  has_many :events
  has_many :machines, :through => :location_machine_xrefs
  has_many :location_machine_xrefs
  has_many :location_picture_xrefs

  geocoded_by :full_street_address, :latitude  => :lat, :longitude => :lon
  before_validation :geocode, :unless => ENV['SKIP_GEOCODE'] || (:lat && :lon)

  scope :region, lambda {|name|
    r = Region.find_by_name(name.downcase) || Region.where(name: 'portland').first

    where(:region_id => r.id)
  }
  scope :by_type_id, lambda {|id| where('location_type_id in (?)', id.split('_').map(&:to_i))}
  scope :by_operator_id, lambda {|id| where(:operator_id => id)}
  scope :by_location_id, lambda {|id| where('id in (?)', id.split('_').map(&:to_i))}
  scope :by_zone_id, lambda {|id| where('zone_id in (?)', id.split('_').map(&:to_i))}
  scope :by_city_id, lambda {|city| where(:city => city)}
  scope :by_location_name, lambda {|name| where(:name => name)}
  scope :by_machine_id, lambda {|id|
    joins(:location_machine_xrefs).where('locations.id = location_machine_xrefs.location_id and location_machine_xrefs.machine_id in(?)', id.split('_').map(&:to_i))
  }
  scope :by_machine_name, lambda {|name|
    machine = Machine.find_by_name(name)

    return nil if machine.nil?

    joins(:location_machine_xrefs).where('locations.id = location_machine_xrefs.location_id and location_machine_xrefs.machine_id = ?', machine.id)
  }
  scope :by_at_least_n_machines_city, lambda {|n|
    where(Location.by_at_least_n_machines_sql(n))
  }
  scope :by_at_least_n_machines_zone, lambda {|n|
    where(Location.by_at_least_n_machines_sql(n))
  }
  scope :by_at_least_n_machines_type, lambda {|n|
    where(Location.by_at_least_n_machines_sql(n))
  }

  before_destroy do |record|
    Event.destroy_all "location_id = #{record.id}"
    LocationPictureXref.destroy_all "location_id = #{record.id}"
    MachineScoreXref.destroy_all "location_machine_xref_id in (select id from location_machine_xrefs where location_id = #{record.id})"
    LocationMachineXref.destroy_all "location_id = #{record.id}"
  end

  def self.by_at_least_n_machines_sql(n)
    "id in (select location_id from (select location_id, count(*) as count from location_machine_xrefs group by location_id) x where x.count >= #{n})"
  end

  def machine_names
    self.machines.sort_by(&:massaged_name).collect { |m| m.name_and_year }
  end

  def content_for_infowindow
    content = "'<div class=\"infowindow\" id=\"infowindow_#{self.id}\">"
    content += "<div class=\"gm_location_name\">#{self.name.gsub("'", "\\\\'")}</div>"
    content += "<div class=\"gm_address\">#{[self.street.gsub("'", "\\\\'"), [self.city.gsub("'", "\\\\'"), self.state, self.zip].join(', '), self.phone].join('<br />')}</div>"
    content += '<hr />'

    machines = self.machine_names.map {|m| m.gsub("'", "\\\\'") + '<br />'}

    content += "<div class=\"gm_machines\" id=\"gm_machines_#{self.id}\">#{machines.join}</div>"
    content += "</div>'"

    content.html_safe
  end

  def full_street_address
    [self.street, self.city, self.state, self.zip].join(', ')
  end

  def newest_machine_xref
    self.location_machine_xrefs.sort_by(&:created_at).last
  end
end
