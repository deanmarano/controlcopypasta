class User < ApplicationRecord

  devise :database_authenticatable,
    :confirmable,
    :lockable,
    #:omniauthable,
    :recoverable,
    :registerable,
    :rememberable,
    #:timeoutable,
    :trackable,
    :validatable
end
