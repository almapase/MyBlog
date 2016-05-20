class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  validates :name, presence: true

  has_many :posts, :dependent => :destroy
  has_many :comments, :dependent => :destroy

  enum role: [:guest, :moderator]

  before_save :default_values

  def default_values
    self.role ||= 0
  end

end
