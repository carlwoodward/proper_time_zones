require 'rubygems'
require 'activesupport'
require 'activerecord'
require 'bacon'
require 'facon'
require 'sqlite3'

Time.zone_default = 'UTC'
Time.zone = 'UTC'
ActiveRecord::Base.time_zone_aware_attributes = true
ActiveRecord::Base.default_timezone = :utc
ActiveRecord::Base.logger = Logger.new STDOUT

ActiveRecord::Base.establish_connection :adapter => "sqlite3", :database  => "test.sqlite3"
# ActiveRecord::Base.establish_connection(:adapter => "postgresql", :database => "proper_time_zones_test", :username => "carl",
#                                         :password => '')

class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :events do |t|
      t.datetime :scheduled_at
      t.date :scheduled_on
      t.timestamps
    end
  end

  def self.down
    drop_table :events
  end
end

class Event < ActiveRecord::Base; end

CreateEvents.down rescue puts("Down failed because db doesn't exist")
CreateEvents.up

describe "time zones messing up" do
  before do
    Time.zone = "Sydney"
    @event = Event.create! :scheduled_at => DateTime.now, :scheduled_on => Date.today
  end
  after do
    Event.destroy_all
  end
  describe "find by date field" do
    it "should find an event on today" do
      today = Time.parse Date.today.strftime('%Y-%m-%d')
      Event.find_by_scheduled_on(today.to_date).should.equal @event
    end
  end
  describe "find by the time field" do
    it "should find an event with time on a date with a parsed time" do
      today = Time.parse Date.today.strftime('%Y-%m-%d')
      Event.find(:first, :conditions => ["date(scheduled_at) = date(?)", today.utc]).should.equal @event
    end
    it "should find an event with time on a date with today" do
      today = Time.today
      Event.find(:first, :conditions => ["date(scheduled_at) = date(?)", today.utc]).should.equal @event
    end
  end
end