class User < ApplicationRecord
# Connects this user object to Blacklights Bookmarks.
 include Blacklight::User
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  #devise :database_authenticatable, :registerable,
         #:recoverable, :rememberable, :trackable, :validatable

  devise :registerable, :trackable, :database_authenticatable, :timeoutable
  devise :omniauthable, :omniauth_providers => [:saml,:google_oauth2,:facebook]
  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me
  # attr_accessible :title, :body

  # validation to prevent low level ActiveRecord::RecordNotUnique exception
  # https://stackoverflow.com/questions/52279663/devise-create-error-message-for-duplicate-username
  validates_uniqueness_of :email

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    email
  end
end
