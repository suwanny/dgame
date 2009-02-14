class State < ActiveRecord::Base
  def self.myStates(id)
    find(:all, :select => 'state_name', :conditions => "alliance=#{id}").map(&:state_name)
  end

  def self.getStates()
    find(:all, :conditions => "user_id > 0")
  end
end
