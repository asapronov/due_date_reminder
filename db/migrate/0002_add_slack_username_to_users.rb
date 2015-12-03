class AddSlackUsernameToUsers < ActiveRecord::Migration

  def self.up
    add_column(:users, "slack_username", :string)
  end

  def self.down
    remove_column(:users, "slack_username")
  end
end
